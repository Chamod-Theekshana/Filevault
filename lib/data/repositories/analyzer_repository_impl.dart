import 'dart:io';

import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/data/database/app_database.dart';
import 'package:filevault/data/services/file_system_service.dart';
import 'package:filevault/domain/models/analyzer_models.dart';
import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:filevault/domain/repositories/analyzer_repository.dart';
import 'package:filevault/domain/repositories/index_repository.dart';
import 'package:filevault/domain/repositories/storage_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AnalyzerRepositoryImpl implements AnalyzerRepository {
  AnalyzerRepositoryImpl(this._db, this._fs, this._index, this._storage);

  final AppDatabase _db;
  final FileSystemService _fs;
  final IndexRepository _index;
  final StorageRepository _storage;

  /// Escapes `%` and `_` so a literal path is not read as a LIKE pattern.
  static String _likeEscape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  static const Set<String> _junkDirNames = <String>{
    'cache', '.cache', 'temp', 'tmp', '.tmp', '.thumbnails', 'thumbnails', '.trash', 'lost+found',
  };
  static const Set<String> _junkExtensions = <String>{
    'tmp', 'temp', 'log', 'bak', 'old', 'part', 'crdownload', 'dmp', 'download', 'partial',
  };
  static const Set<String> _protectedFolders = <String>{
    'DCIM', 'Download', 'Pictures', 'Movies', 'Music', 'Documents', 'Alarms', 'Ringtones',
    'Notifications', 'Podcasts', 'Android', 'Audiobooks', 'Recordings',
  };

  @override
  Future<StorageBreakdown> breakdown({ProgressCallback? onProgress, CancelToken? cancelToken}) async {
    if (await _index.isEmpty) {
      await _index.rebuild(includeHidden: false, onProgress: onProgress, cancelToken: cancelToken);
    }
    final StorageVolume volume = await _storage.primaryVolume();
    final List<CategorySummary> categories = await _index.categorySummaries();
    final Map<String, int> folders = await _index.folderSizes(limit: 10);
    final List<FileEntry> largest = await _index.largestFiles(limit: 10);
    final List<Map<String, Object?>> totals = await _db.db.rawQuery(
      'SELECT COUNT(*) AS n, COALESCE(SUM(size), 0) AS bytes FROM file_index WHERE is_directory = 0',
    );
    final List<FolderSize> folderSizes = <FolderSize>[];
    for (final MapEntry<String, int> e in folders.entries) {
      final List<Map<String, Object?>> count = await _db.db.rawQuery(
        "SELECT COUNT(*) AS n FROM file_index "
        "WHERE is_directory = 0 AND path LIKE ? ESCAPE '\\'",
        <Object?>['${_likeEscape(e.key)}/%'],
      );
      folderSizes.add(FolderSize(
        path: e.key,
        name: p.basename(e.key),
        bytes: e.value,
        fileCount: (count.first['n'] as num).toInt(),
      ));
    }
    return StorageBreakdown(
      volume: volume,
      categories: categories,
      largestFolders: folderSizes,
      largestFiles: largest,
      scannedFiles: (totals.first['n'] as num).toInt(),
      scannedBytes: (totals.first['bytes'] as num).toInt(),
    );
  }

  @override
  Future<List<FileEntry>> largeFiles({int minBytes = AppConstants.largeFileThresholdBytes, int limit = 200}) =>
      _index.largestFiles(limit: limit, minBytes: minBytes);

  // ---------------------------------------------------------- duplicates

  @override
  Future<List<DuplicateGroup>> findDuplicates({ProgressCallback? onProgress, CancelToken? cancelToken}) async {
    if (await _index.isEmpty) {
      await _index.rebuild(includeHidden: false, cancelToken: cancelToken);
    }
    // Step 1: candidate files that share a size with at least one other.
    final List<Map<String, Object?>> rows = await _db.db.rawQuery(
      'SELECT * FROM file_index WHERE is_directory = 0 AND size > 4096 AND size IN '
      '(SELECT size FROM file_index WHERE is_directory = 0 AND size > 4096 '
      'GROUP BY size HAVING COUNT(*) > 1) ORDER BY size DESC LIMIT 20000',
    );
    final List<FileEntry> candidates = rows.map(_entryFromIndexRow).toList();
    onProgress?.call(0.05, null);
    if (candidates.isEmpty) return const <DuplicateGroup>[];

    // Step 2: reuse cached hashes where path/size/mtime still match.
    final Map<String, String> hashes = <String, String>{};
    final List<FileEntry> toHash = <FileEntry>[];
    for (final FileEntry e in candidates) {
      final List<Map<String, Object?>> cached = await _db.db.query(
        'hash_cache',
        where: 'path = ? AND size = ? AND modified = ?',
        whereArgs: <Object?>[e.path, e.size, e.modified.millisecondsSinceEpoch],
        limit: 1,
      );
      if (cached.isNotEmpty) {
        hashes[e.path] = cached.first['sha256']! as String;
      } else {
        toHash.add(e);
      }
    }
    onProgress?.call(0.1, null);

    // Step 3: hash the rest in a worker isolate.
    if (toHash.isNotEmpty) {
      final Map<String, String> fresh = await IsolateWorker.run<List<String>, Map<String, String>>(
        toHash.map((FileEntry e) => e.path).toList(),
        _hashManyJob,
        onProgress: (double f, String? label) => onProgress?.call(0.1 + f * 0.85, label),
        cancelToken: cancelToken,
        debugName: 'dup-hash',
      );
      hashes.addAll(fresh);
      final Batch batch = _db.db.batch();
      for (final FileEntry e in toHash) {
        final String? h = fresh[e.path];
        if (h == null) continue;
        batch.insert(
          'hash_cache',
          <String, Object?>{
            'path': e.path,
            'size': e.size,
            'modified': e.modified.millisecondsSinceEpoch,
            'sha256': h,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }

    // Step 4: group by hash.
    final Map<String, List<FileEntry>> groups = <String, List<FileEntry>>{};
    for (final FileEntry e in candidates) {
      final String? h = hashes[e.path];
      if (h == null || h.isEmpty) continue;
      groups.putIfAbsent(h, () => <FileEntry>[]).add(e);
    }
    final List<DuplicateGroup> out = <DuplicateGroup>[];
    for (final MapEntry<String, List<FileEntry>> g in groups.entries) {
      if (g.value.length < 2) continue;
      g.value.sort((FileEntry a, FileEntry b) => b.modified.compareTo(a.modified));
      out.add(DuplicateGroup(hash: g.key, size: g.value.first.size, files: g.value));
    }
    out.sort((DuplicateGroup a, DuplicateGroup b) => b.wastedBytes.compareTo(a.wastedBytes));
    onProgress?.call(1, null);
    return out;
  }

  static Future<Map<String, String>> _hashManyJob(List<String> paths, WorkerContext ctx) async {
    final Map<String, String> out = <String, String>{};
    for (int i = 0; i < paths.length; i++) {
      final String path = paths[i];
      try {
        out[path] = await FileSystemService.hashFileSync(path);
      } catch (_) {}
      ctx.report((i + 1) / paths.length, p.basename(path));
      if (i % 3 == 0) await ctx.checkpoint();
    }
    return out;
  }

  FileEntry _entryFromIndexRow(Map<String, Object?> r) => FileEntry.fromMap(<String, Object?>{
        'path': r['path'],
        'name': r['name'],
        'isDirectory': r['is_directory'],
        'size': r['size'],
        'modified': r['modified'],
        'category': r['category'],
        'mimeType': r['mime_type'],
        'extension': r['extension'],
        'isHidden': r['is_hidden'],
      });

  // ---------------------------------------------------------------- junk

  @override
  Future<JunkReport> scanJunk({ProgressCallback? onProgress, CancelToken? cancelToken}) async {
    final List<String> roots = await _storage.scanRoots();
    final List<Object?> raw = await IsolateWorker.run<List<String>, List<Object?>>(
      roots,
      _junkJob,
      onProgress: onProgress,
      cancelToken: cancelToken,
      debugName: 'junk-scan',
    );
    final List<JunkItem> items = raw.whereType<Map<String, Object?>>().map((Map<String, Object?> m) {
      return JunkItem(
        path: m['path']! as String,
        name: m['name']! as String,
        bytes: (m['bytes'] as num?)?.toInt() ?? 0,
        kind: JunkKind.values[(m['kind'] as num).toInt()],
        isDirectory: m['isDirectory'] == true,
      );
    }).toList();
    items.sort((JunkItem a, JunkItem b) => b.bytes.compareTo(a.bytes));
    return JunkReport(items: items);
  }

  static Future<List<Object?>> _junkJob(List<String> roots, WorkerContext ctx) async {
    final List<Object?> out = <Object?>[];
    int visited = 0;
    for (final String root in roots) {
      final List<String> stack = <String>[root];
      while (stack.isNotEmpty) {
        // Checkpoint before any `continue` so skipped folders still yield and
        // the scan stays cancellable.
        if (++visited % 60 == 0) {
          ctx.report((1 - 1 / (1 + visited / 400)) * 0.95, stack.last);
          await ctx.checkpoint();
        }
        final String dir = stack.removeLast();
        if (_isRestricted(dir)) continue;
        List<FileSystemEntity> children;
        try {
          children = Directory(dir).listSync(followLinks: false);
        } catch (_) {
          continue;
        }
        final String dirName = p.basename(dir);
        final bool isJunkDir = _junkDirNames.contains(dirName.toLowerCase()) && dir != root;
        if (isJunkDir) {
          final int bytes = _sizeOf(dir);
          out.add(_junk(dir, dirName, bytes, dirName.toLowerCase().contains('thumb') ? JunkKind.thumbnail : JunkKind.cache, true));
          continue; // don't descend into something we will delete whole
        }
        if (children.isEmpty &&
            dir != root &&
            p.dirname(dir) != root &&
            !_protectedFolders.contains(dirName) &&
            !dirName.startsWith('.')) {
          out.add(_junk(dir, dirName, 0, JunkKind.emptyFolder, true));
          continue;
        }
        for (final FileSystemEntity e in children) {
          final String name = p.basename(e.path);
          if (e is Directory) {
            if (name == AppConstants.trashFolderName) continue;
            stack.add(e.path);
          } else if (e is File) {
            final int dot = name.lastIndexOf('.');
            final String ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
            if (_junkExtensions.contains(ext)) {
              int bytes = 0;
              try {
                bytes = e.lengthSync();
              } catch (_) {}
              final JunkKind kind = ext == 'log' ? JunkKind.log : JunkKind.temp;
              out.add(_junk(e.path, name, bytes, kind, false));
            }
          }
        }
      }
    }
    ctx.report(1);
    return out;
  }

  static Map<String, Object?> _junk(String path, String name, int bytes, JunkKind kind, bool isDir) =>
      <String, Object?>{
        'path': path,
        'name': name,
        'bytes': bytes,
        'kind': kind.index,
        'isDirectory': isDir,
      };

  static int _sizeOf(String dir) {
    int bytes = 0;
    final List<String> stack = <String>[dir];
    while (stack.isNotEmpty) {
      final String d = stack.removeLast();
      try {
        for (final FileSystemEntity e in Directory(d).listSync(followLinks: false)) {
          if (e is Directory) {
            stack.add(e.path);
          } else if (e is File) {
            try {
              bytes += e.lengthSync();
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
    return bytes;
  }

  static bool _isRestricted(String path) {
    for (final String r in AppConstants.restrictedFolders) {
      if (path == r || path.startsWith('$r/')) return true;
    }
    return false;
  }

  @override
  Future<int> deleteJunk(List<JunkItem> items) async {
    int freed = 0;
    for (final JunkItem item in items) {
      try {
        await _fs.deleteEntity(item.path);
        await _index.removePath(item.path);
        freed += item.bytes;
      } catch (_) {}
    }
    return freed;
  }
}
