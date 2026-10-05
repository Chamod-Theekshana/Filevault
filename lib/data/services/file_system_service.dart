import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/repositories/file_repository.dart';
import 'package:path/path.dart' as p;

/// Direct `dart:io` access. This is the only place in the app that walks,
/// copies or writes real files (besides the archive and vault engines).
class FileSystemService {
  const FileSystemService();

  // ------------------------------------------------------------ listing

  /// Emits batches of entries so huge folders paint progressively.
  Stream<List<FileEntry>> list(String path, {required bool showHidden}) async* {
    final Directory dir = Directory(path);
    if (!await dir.exists()) {
      throw NotFoundFailure(path: path);
    }
    List<FileEntry> batch = <FileEntry>[];
    try {
      await for (final FileSystemEntity entity in dir.list(followLinks: false)) {
        final String name = p.basename(entity.path);
        final bool hidden = name.startsWith('.');
        if (hidden && !showHidden) continue;
        final FileEntry? entry = await _safeEntry(entity.path, name);
        if (entry == null) continue;
        batch.add(entry);
        if (batch.length >= AppConstants.listBatchSize) {
          yield batch;
          batch = <FileEntry>[];
        }
      }
    } on FileSystemException catch (e) {
      throw Failure.fromException(e, path: path);
    }
    if (batch.isNotEmpty) yield batch;
  }

  Future<FileEntry?> _safeEntry(String path, String name) async {
    try {
      final FileStat stat = await FileStat.stat(path);
      if (stat.type == FileSystemEntityType.notFound) return null;
      return entryFromStat(path, stat, name: name);
    } catch (_) {
      return null;
    }
  }

  static FileEntry entryFromStat(String path, FileStat stat, {String? name}) {
    final String base = name ?? p.basename(path);
    final bool isDir = stat.type == FileSystemEntityType.directory;
    final String ext = isDir ? '' : FileUtils.extensionOf(base);
    return FileEntry(
      path: path,
      name: base,
      isDirectory: isDir,
      size: isDir ? 0 : stat.size,
      modified: stat.modified,
      category: FileUtils.categoryFor(base, isDirectory: isDir),
      mimeType: isDir ? null : FileUtils.mimeFor(base),
      extension: ext,
      isHidden: base.startsWith('.'),
    );
  }

  Future<FileEntry> stat(String path) async {
    final FileStat stat = await FileStat.stat(path);
    if (stat.type == FileSystemEntityType.notFound) {
      throw NotFoundFailure(path: path);
    }
    return entryFromStat(path, stat);
  }

  Future<bool> exists(String path) async {
    final FileSystemEntityType type = await FileSystemEntity.type(path, followLinks: false);
    return type != FileSystemEntityType.notFound;
  }

  bool existsSync(String path) =>
      FileSystemEntity.typeSync(path, followLinks: false) != FileSystemEntityType.notFound;

  Future<int> countChildren(String path) async {
    int n = 0;
    try {
      await for (final FileSystemEntity _ in Directory(path).list(followLinks: false)) {
        n++;
      }
    } catch (_) {}
    return n;
  }

  // ----------------------------------------------------------- creating

  Future<FileEntry> createFolder(String parentPath, String name) async {
    _validateName(name);
    final String target = p.join(parentPath, name);
    if (existsSync(target)) throw AlreadyExistsFailure(path: target);
    await Directory(target).create();
    return stat(target);
  }

  Future<FileEntry> createFile(String parentPath, String name) async {
    _validateName(name);
    final String target = p.join(parentPath, name);
    if (existsSync(target)) throw AlreadyExistsFailure(path: target);
    await File(target).create();
    return stat(target);
  }

  Future<FileEntry> rename(String path, String newName) async {
    _validateName(newName);
    final String target = p.join(p.dirname(path), newName);
    if (target == path) return stat(path);
    if (existsSync(target)) throw AlreadyExistsFailure(path: target);
    final FileSystemEntityType type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).rename(target);
    } else {
      await File(path).rename(target);
    }
    return stat(target);
  }

  Future<FileEntry> duplicate(String path) async {
    final String target = FileUtils.uniquePathSync(path);
    final FileSystemEntityType type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      await copyDirectory(path, target);
    } else {
      await File(path).copy(target);
    }
    return stat(target);
  }

  void _validateName(String name) {
    if (!FileUtils.isValidName(name)) {
      throw const InvalidNameFailure();
    }
  }

  // ------------------------------------------------------------ copying

  /// Streams [source] into [destination] in chunks. Supports pause/cancel
  /// and reports copied bytes so speed can be measured.
  Future<void> copyFile(
    String source,
    String destination, {
    void Function(int bytesCopied)? onBytes,
    PauseGate? gate,
    CancelToken? cancelToken,
  }) async {
    final File src = File(source);
    final File dst = File(destination);
    await dst.parent.create(recursive: true);
    final IOSink sink = dst.openWrite();
    try {
      await for (final List<int> chunk in src.openRead()) {
        if (gate != null) await gate.wait();
        cancelToken?.throwIfCancelled();
        sink.add(chunk);
        onBytes?.call(chunk.length);
      }
      await sink.flush();
      await sink.close();
    } catch (e) {
      try {
        await sink.close();
      } catch (_) {}
      try {
        if (await dst.exists()) await dst.delete();
      } catch (_) {}
      rethrow;
    }
    try {
      final FileStat s = await src.stat();
      await dst.setLastModified(s.modified);
    } catch (_) {}
  }

  Future<void> copyDirectory(String source, String destination) async {
    await Directory(destination).create(recursive: true);
    await for (final FileSystemEntity entity
        in Directory(source).list(followLinks: false)) {
      final String target = p.join(destination, p.basename(entity.path));
      if (entity is Directory) {
        await copyDirectory(entity.path, target);
      } else if (entity is File) {
        await entity.copy(target);
      }
    }
  }

  /// Rename when possible (same volume), otherwise the caller falls back to
  /// copy + delete. Returns true when the rename succeeded.
  Future<bool> tryRename(String source, String destination) async {
    try {
      final FileSystemEntityType type =
          await FileSystemEntity.type(source, followLinks: false);
      if (type == FileSystemEntityType.directory) {
        await Directory(source).rename(destination);
      } else {
        await File(source).rename(destination);
      }
      return true;
    } on FileSystemException catch (e) {
      final int code = e.osError?.errorCode ?? -1;
      // EXDEV (18) = cross-device link: must copy instead.
      if (code == 18) return false;
      rethrow;
    }
  }

  Future<void> deleteEntity(String path) async {
    final FileSystemEntityType type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return;
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else if (type == FileSystemEntityType.link) {
      await Link(path).delete();
    } else {
      await File(path).delete();
    }
  }

  /// Flat list of every file below [root] with its size, for pre-flight
  /// totals and progress maths. Directories are not included.
  Future<List<FileEntry>> flatten(String root, {CancelToken? cancelToken}) async {
    final List<FileEntry> out = <FileEntry>[];
    final FileStat rootStat = await FileStat.stat(root);
    if (rootStat.type != FileSystemEntityType.directory) {
      out.add(entryFromStat(root, rootStat));
      return out;
    }
    final List<String> stack = <String>[root];
    while (stack.isNotEmpty) {
      cancelToken?.throwIfCancelled();
      final String dir = stack.removeLast();
      try {
        await for (final FileSystemEntity e in Directory(dir).list(followLinks: false)) {
          if (e is Directory) {
            stack.add(e.path);
          } else if (e is File) {
            final FileStat s = await e.stat();
            out.add(entryFromStat(e.path, s));
          }
        }
      } on FileSystemException {
        // Unreadable subfolder – skip it rather than abort the whole op.
      }
    }
    return out;
  }

  /// Rough check used by move: both paths under the same top-level volume.
  ///
  /// `/storage/emulated/0/...` is internal storage; `/storage/XXXX-XXXX/...`
  /// is a removable card. A volume root itself must resolve to the same root
  /// as the files inside it, so the segment count is clamped.
  static bool sameVolume(String a, String b) {
    String root(String path) {
      final List<String> parts = p.split(p.normalize(path));
      if (parts.length >= 3 && parts[1] == 'storage') {
        final int wanted = parts[2] == 'emulated' ? 4 : 3;
        return p.joinAll(parts.take(wanted > parts.length ? parts.length : wanted));
      }
      return parts.length > 1 ? p.joinAll(parts.take(2)) : '/';
    }

    return root(a) == root(b);
  }

  // ------------------------------------------------------- heavy jobs

  Future<DirectoryStats> directoryStats(String path, {CancelToken? cancelToken}) {
    return IsolateWorker.run<String, DirectoryStats>(
      path,
      _statsJob,
      cancelToken: cancelToken,
      debugName: 'dir-stats',
    );
  }

  static Future<DirectoryStats> _statsJob(String root, WorkerContext ctx) async {
    int files = 0;
    int folders = 0;
    int bytes = 0;
    final List<String> stack = <String>[root];
    int visited = 0;
    while (stack.isNotEmpty) {
      final String dir = stack.removeLast();
      try {
        for (final FileSystemEntity e in Directory(dir).listSync(followLinks: false)) {
          if (e is Directory) {
            folders++;
            stack.add(e.path);
          } else if (e is File) {
            files++;
            try {
              bytes += e.lengthSync();
            } catch (_) {}
          }
        }
      } catch (_) {}
      if (++visited % 50 == 0) await ctx.checkpoint();
    }
    return DirectoryStats(files: files, folders: folders, bytes: bytes);
  }

  Future<String> computeHash(
    String path,
    HashAlgorithm algorithm, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) {
    return IsolateWorker.run<List<String>, String>(
      <String>[path, algorithm.name],
      _hashJob,
      cancelToken: cancelToken,
      onProgress: onProgress,
      debugName: 'hash',
    );
  }

  static Future<String> _hashJob(List<String> args, WorkerContext ctx) async {
    final File file = File(args[0]);
    final Hash hash = args[1] == 'md5' ? md5 : sha256;
    final int total = file.lengthSync();
    final _DigestSink out = _DigestSink();
    final ByteConversionSink input = hash.startChunkedConversion(out);
    final RandomAccessFile raf = file.openSync();
    try {
      int done = 0;
      int iterations = 0;
      while (true) {
        final Uint8List chunk = raf.readSync(1024 * 1024);
        if (chunk.isEmpty) break;
        input.add(chunk);
        done += chunk.length;
        if (total > 0) ctx.report(done / total);
        if (++iterations % 8 == 0) await ctx.checkpoint();
      }
    } finally {
      raf.closeSync();
    }
    input.close();
    return out.value?.toString() ?? '';
  }

  /// Synchronous SHA-256 of a whole file; only call from a worker isolate.
  static Future<String> hashFileSync(String path) async {
    final File file = File(path);
    final _DigestSink out = _DigestSink();
    final ByteConversionSink input = sha256.startChunkedConversion(out);
    final RandomAccessFile raf = file.openSync();
    try {
      while (true) {
        final Uint8List chunk = raf.readSync(1024 * 1024);
        if (chunk.isEmpty) break;
        input.add(chunk);
      }
    } finally {
      raf.closeSync();
    }
    input.close();
    return out.value?.toString() ?? '';
  }

  /// Walks [root] in a worker and returns matching files. Used by category
  /// folders before the index exists and by the analyzer.
  Future<List<FileEntry>> walk(
    String root, {
    required bool includeHidden,
    int limit = 5000,
    Set<String>? categories,
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) {
    return IsolateWorker.run<Map<String, Object?>, List<FileEntry>>(
      <String, Object?>{
        'root': root,
        'hidden': includeHidden,
        'limit': limit,
        'categories': categories?.toList(),
      },
      _walkJob,
      cancelToken: cancelToken,
      onProgress: onProgress,
      debugName: 'walk',
    );
  }

  static Future<List<FileEntry>> _walkJob(
    Map<String, Object?> args,
    WorkerContext ctx,
  ) async {
    final String root = args['root']! as String;
    final bool hidden = args['hidden'] == true;
    final int limit = (args['limit'] as int?) ?? 5000;
    final List<Object?>? cats = args['categories'] as List<Object?>?;
    final Set<String>? categories = cats?.map((Object? e) => e.toString()).toSet();
    final List<FileEntry> out = <FileEntry>[];
    final List<String> stack = <String>[root];
    int visited = 0;
    while (stack.isNotEmpty && out.length < limit) {
      // Checkpoint first: restricted folders `continue` below and would
      // otherwise skip the cancellation point entirely.
      if (++visited % 40 == 0) {
        ctx.report((1 - 1 / (1 + visited / 300)) * 0.95, stack.last);
        await ctx.checkpoint();
      }
      final String dir = stack.removeLast();
      if (_isRestricted(dir)) continue;
      try {
        for (final FileSystemEntity e in Directory(dir).listSync(followLinks: false)) {
          final String name = p.basename(e.path);
          if (!hidden && name.startsWith('.')) continue;
          if (e is Directory) {
            stack.add(e.path);
          } else if (e is File) {
            final FileCategory category = FileUtils.categoryFor(name);
            if (categories != null && !categories.contains(category.name)) continue;
            try {
              out.add(entryFromStat(e.path, e.statSync(), name: name));
            } catch (_) {}
            if (out.length >= limit) break;
          }
        }
      } catch (_) {}
    }
    ctx.report(1);
    return out;
  }

  static bool _isRestricted(String path) {
    for (final String r in AppConstants.restrictedFolders) {
      if (path == r || path.startsWith('$r/')) return true;
    }
    return false;
  }

  bool isRestricted(String path) => _isRestricted(path);

  // ---------------------------------------------------------- text I/O

  Future<TextDocument> readText(String path) async {
    final Uint8List bytes = await File(path).readAsBytes();
    if (bytes.length > AppConstants.textEditorMaxBytes) {
      throw const IoFailure(message: 'too large');
    }
    return decodeText(bytes);
  }

  static TextDocument decodeText(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return TextDocument(
          content: _utf16(bytes, 2, littleEndian: true), encoding: 'UTF-16LE', bytes: bytes.length);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return TextDocument(
          content: _utf16(bytes, 2, littleEndian: false), encoding: 'UTF-16BE', bytes: bytes.length);
    }
    int start = 0;
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      start = 3;
    }
    try {
      return TextDocument(
        content: utf8.decode(bytes.sublist(start)),
        encoding: 'UTF-8',
        bytes: bytes.length,
      );
    } on FormatException {
      return TextDocument(
        content: latin1.decode(bytes),
        encoding: 'ISO-8859-1',
        bytes: bytes.length,
      );
    }
  }

  static String _utf16(Uint8List bytes, int start, {required bool littleEndian}) {
    final List<int> units = <int>[];
    for (int i = start; i + 1 < bytes.length; i += 2) {
      units.add(littleEndian ? bytes[i] | (bytes[i + 1] << 8) : (bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(units);
  }

  Future<void> writeText(String path, String content, {String encoding = 'utf-8'}) async {
    final List<int> bytes = switch (encoding.toLowerCase()) {
      'iso-8859-1' || 'latin1' => latin1.encode(content),
      _ => utf8.encode(content),
    };
    await File(path).writeAsBytes(bytes, flush: true);
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
