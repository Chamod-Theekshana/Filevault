import 'dart:io';

import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/data/database/app_database.dart';
import 'package:filevault/data/services/file_system_service.dart';
import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/search_models.dart';
import 'package:filevault/domain/repositories/index_repository.dart';
import 'package:filevault/domain/repositories/storage_repository.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class IndexRepositoryImpl implements IndexRepository {
  IndexRepositoryImpl(this._db, this._storage);

  final AppDatabase _db;
  final StorageRepository _storage;
  bool _running = false;

  Database get _sql => _db.db;

  /// Escapes a value used inside a SQL `LIKE` pattern. File names regularly
  /// contain `_` and `%`, which would otherwise act as wildcards.
  static String _likeEscape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  // ------------------------------------------------------------- rebuild

  @override
  Future<int> rebuild({
    required bool includeHidden,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (_running) return 0;
    _running = true;
    try {
      final List<String> roots = await _storage.scanRoots();
      final List<FileEntry> entries = await IsolateWorker.run<Map<String, Object?>, List<FileEntry>>(
        <String, Object?>{'roots': roots, 'hidden': includeHidden},
        _scanJob,
        onProgress: (double f, String? label) => onProgress?.call(f * 0.8, label),
        cancelToken: cancelToken,
        debugName: 'index-scan',
      );
      cancelToken?.throwIfCancelled();
      await _sql.transaction((Transaction txn) async {
        await txn.delete('file_index');
        const int chunk = 500;
        for (int i = 0; i < entries.length; i += chunk) {
          final Batch batch = txn.batch();
          for (final FileEntry e in entries.skip(i).take(chunk)) {
            batch.insert('file_index', _row(e), conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await batch.commit(noResult: true);
          onProgress?.call(0.8 + 0.2 * (i / entries.length), null);
        }
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.prefsLastIndexAt, DateTime.now().millisecondsSinceEpoch);
      onProgress?.call(1, null);
      return entries.where((FileEntry e) => !e.isDirectory).length;
    } finally {
      _running = false;
    }
  }

  static Future<List<FileEntry>> _scanJob(Map<String, Object?> args, WorkerContext ctx) async {
    final List<String> roots =
        (args['roots']! as List<Object?>).map((Object? e) => e.toString()).toList();
    final bool hidden = args['hidden'] == true;
    final List<FileEntry> out = <FileEntry>[];
    const int cap = 400000;
    for (final String root in roots) {
      final List<String> stack = <String>[root];
      int visited = 0;
      while (stack.isNotEmpty && out.length < cap) {
        // Checkpoint first so folders that are skipped below still yield and
        // observe cancellation.
        if (++visited % 60 == 0) {
          // Progress is unknowable ahead of time; ease towards 0.95.
          final double f = 1 - 1 / (1 + visited / 400);
          ctx.report(f * 0.95, stack.last);
          await ctx.checkpoint();
        }
        final String dir = stack.removeLast();
        if (_restricted(dir)) continue;
        if (p.basename(dir) == AppConstants.trashFolderName) continue;
        List<FileSystemEntity> children;
        try {
          children = Directory(dir).listSync(followLinks: false);
        } catch (_) {
          continue;
        }
        for (final FileSystemEntity e in children) {
          final String name = p.basename(e.path);
          if (!hidden && name.startsWith('.')) continue;
          try {
            final FileStat stat = e.statSync();
            if (stat.type == FileSystemEntityType.directory) {
              stack.add(e.path);
              out.add(FileSystemService.entryFromStat(e.path, stat, name: name));
            } else if (stat.type == FileSystemEntityType.file) {
              out.add(FileSystemService.entryFromStat(e.path, stat, name: name));
            }
          } catch (_) {}
        }
      }
    }
    ctx.report(1);
    return out;
  }

  static bool _restricted(String path) {
    for (final String r in AppConstants.restrictedFolders) {
      if (path == r || path.startsWith('$r/')) return true;
    }
    return false;
  }

  Map<String, Object?> _row(FileEntry e) => <String, Object?>{
        'path': e.path,
        'name': e.name,
        'name_lower': e.name.toLowerCase(),
        'parent_path': e.parentPath,
        'size': e.size,
        'modified': e.modified.millisecondsSinceEpoch,
        'is_directory': e.isDirectory ? 1 : 0,
        'is_hidden': e.isHidden ? 1 : 0,
        'mime_type': e.mimeType,
        'extension': e.extension,
        'category': e.category.name,
      };

  FileEntry _entry(Map<String, Object?> r) => FileEntry(
        path: r['path']! as String,
        name: r['name']! as String,
        isDirectory: (r['is_directory'] as num?) == 1,
        size: (r['size'] as num?)?.toInt() ?? 0,
        modified: DateTime.fromMillisecondsSinceEpoch((r['modified'] as num?)?.toInt() ?? 0),
        category: FileCategory.fromName(r['category'] as String?),
        mimeType: r['mime_type'] as String?,
        extension: (r['extension'] as String?) ?? '',
        isHidden: (r['is_hidden'] as num?) == 1,
      );

  // -------------------------------------------------------------- status

  @override
  Future<IndexStatus> status() async {
    final List<Map<String, Object?>> rows =
        await _sql.rawQuery('SELECT COUNT(*) AS n FROM file_index WHERE is_directory = 0');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? at = prefs.getInt(AppConstants.prefsLastIndexAt);
    return IndexStatus(
      isRunning: _running,
      indexedFiles: (rows.first['n'] as num?)?.toInt() ?? 0,
      lastIndexedAt: at == null ? null : DateTime.fromMillisecondsSinceEpoch(at),
    );
  }

  @override
  Future<bool> get isEmpty async {
    final List<Map<String, Object?>> rows =
        await _sql.query('file_index', columns: <String>['path'], limit: 1);
    return rows.isEmpty;
  }

  // -------------------------------------------------------------- search

  @override
  Future<List<SearchHit>> search(String query, SearchFilter filter, {int limit = 300}) async {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return const <SearchHit>[];
    final String escaped = _likeEscape(q);
    final StringBuffer where = StringBuffer("name_lower LIKE ? ESCAPE '\\'");
    final List<Object?> args = <Object?>['%$escaped%'];
    if (filter.category != null) {
      where.write(' AND category = ?');
      args.add(filter.category!.name);
    }
    if (!filter.includeHidden) where.write(' AND is_hidden = 0');
    final int? min = filter.minBytes;
    final int? max = filter.maxBytes;
    if (min != null) {
      where.write(' AND size >= ?');
      args.add(min);
    }
    if (max != null) {
      where.write(' AND size < ?');
      args.add(max);
    }
    final DateTime? since = filter.since();
    if (since != null) {
      where.write(' AND modified >= ?');
      args.add(since.millisecondsSinceEpoch);
    }
    args.add('$escaped%');
    args.add(limit);
    final List<Map<String, Object?>> rows = await _sql.rawQuery(
      'SELECT * FROM file_index WHERE $where '
      "ORDER BY (name_lower LIKE ? ESCAPE '\\') DESC, is_directory DESC, modified DESC LIMIT ?",
      args,
    );
    return rows.map((Map<String, Object?> r) => SearchHit.forQuery(_entry(r), q)).toList();
  }

  // ---------------------------------------------------------- statistics

  @override
  Future<List<CategorySummary>> categorySummaries() async {
    final List<Map<String, Object?>> rows = await _sql.rawQuery(
      'SELECT category, COUNT(*) AS n, COALESCE(SUM(size), 0) AS bytes '
      'FROM file_index WHERE is_directory = 0 GROUP BY category',
    );
    final Map<FileCategory, CategorySummary> map = <FileCategory, CategorySummary>{
      for (final FileCategory c in FileCategory.values) c: CategorySummary.empty(c),
    };
    for (final Map<String, Object?> r in rows) {
      final FileCategory c = FileCategory.fromName(r['category'] as String?);
      map[c] = CategorySummary(
        category: c,
        itemCount: (r['n'] as num).toInt(),
        totalBytes: (r['bytes'] as num).toInt(),
      );
    }
    final List<Map<String, Object?>> dl = await _sql.rawQuery(
      'SELECT COUNT(*) AS n, COALESCE(SUM(size), 0) AS bytes FROM file_index '
      "WHERE is_directory = 0 AND path LIKE ? ESCAPE '\\'",
      <Object?>['${_likeEscape(_storage.downloadsPath)}/%'],
    );
    map[FileCategory.downloads] = CategorySummary(
      category: FileCategory.downloads,
      itemCount: (dl.first['n'] as num).toInt(),
      totalBytes: (dl.first['bytes'] as num).toInt(),
    );
    return map.values.toList(growable: false);
  }

  @override
  Future<List<FileEntry>> filesInCategory(
    FileCategory category, {
    int limit = 2000,
    int offset = 0,
    String? underPath,
  }) async {
    final List<Map<String, Object?>> rows;
    if (category == FileCategory.downloads) {
      rows = await _sql.query(
        'file_index',
        where: 'parent_path = ?',
        whereArgs: <Object?>[underPath ?? _storage.downloadsPath],
        orderBy: 'is_directory DESC, modified DESC',
        limit: limit,
        offset: offset,
      );
    } else {
      rows = await _sql.query(
        'file_index',
        where: underPath == null
            ? 'category = ? AND is_directory = 0'
            : "category = ? AND is_directory = 0 AND path LIKE ? ESCAPE '\\'",
        whereArgs: underPath == null
            ? <Object?>[category.name]
            : <Object?>[category.name, '${_likeEscape(underPath)}/%'],
        orderBy: 'modified DESC',
        limit: limit,
        offset: offset,
      );
    }
    return rows.map(_entry).toList(growable: false);
  }

  @override
  Future<List<FileEntry>> largestFiles({int limit = 100, int minBytes = 0}) async {
    final List<Map<String, Object?>> rows = await _sql.query(
      'file_index',
      where: 'is_directory = 0 AND size >= ?',
      whereArgs: <Object?>[minBytes],
      orderBy: 'size DESC',
      limit: limit,
    );
    return rows.map(_entry).toList(growable: false);
  }

  @override
  Future<Map<String, int>> folderSizes({int limit = 12}) async {
    final List<String> roots = await _storage.scanRoots();
    final Map<String, int> sizes = <String, int>{};
    for (final String root in roots) {
      final List<Map<String, Object?>> dirs = await _sql.query(
        'file_index',
        columns: <String>['path'],
        where: 'parent_path = ? AND is_directory = 1',
        whereArgs: <Object?>[root],
      );
      for (final Map<String, Object?> d in dirs) {
        final String path = d['path']! as String;
        final List<Map<String, Object?>> sum = await _sql.rawQuery(
          "SELECT COALESCE(SUM(size), 0) AS bytes FROM file_index "
          "WHERE is_directory = 0 AND path LIKE ? ESCAPE '\\'",
          <Object?>['${_likeEscape(path)}/%'],
        );
        sizes[path] = (sum.first['bytes'] as num).toInt();
      }
    }
    final List<MapEntry<String, int>> sorted = sizes.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));
    return Map<String, int>.fromEntries(sorted.take(limit));
  }

  // ------------------------------------------------------ recent searches

  @override
  Future<List<String>> recentSearches() async {
    final List<Map<String, Object?>> rows = await _sql.query(
      'search_history',
      orderBy: 'searched_at DESC',
      limit: AppConstants.maxRecentSearches,
    );
    return rows.map((Map<String, Object?> r) => r['query']! as String).toList();
  }

  @override
  Future<void> addRecentSearch(String query) async {
    final String q = query.trim();
    if (q.isEmpty) return;
    await _sql.insert(
      'search_history',
      <String, Object?>{'query': q, 'searched_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeRecentSearch(String query) =>
      _sql.delete('search_history', where: 'query = ?', whereArgs: <Object?>[query]);

  @override
  Future<void> clearRecentSearches() => _sql.delete('search_history');

  // --------------------------------------------------------- incremental

  @override
  Future<void> upsertEntries(List<FileEntry> entries) async {
    if (entries.isEmpty) return;
    final Batch batch = _sql.batch();
    for (final FileEntry e in entries) {
      batch.insert('file_index', _row(e), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removePath(String path) async {
    await _sql.delete('file_index',
        where: "path = ? OR path LIKE ? ESCAPE '\\'",
        whereArgs: <Object?>[path, '${_likeEscape(path)}/%']);
  }

  @override
  Future<void> movePath(String oldPath, String newPath) async {
    final List<Map<String, Object?>> rows = await _sql.query(
      'file_index',
      where: "path = ? OR path LIKE ? ESCAPE '\\'",
      whereArgs: <Object?>[oldPath, '${_likeEscape(oldPath)}/%'],
    );
    if (rows.isEmpty) return;
    final Batch batch = _sql.batch();
    for (final Map<String, Object?> r in rows) {
      final String old = r['path']! as String;
      final String fresh = newPath + old.substring(oldPath.length);
      final FileEntry moved = _entry(r).copyWith(path: fresh, name: p.basename(fresh));
      batch.delete('file_index', where: 'path = ?', whereArgs: <Object?>[old]);
      batch.insert('file_index', _row(moved), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
