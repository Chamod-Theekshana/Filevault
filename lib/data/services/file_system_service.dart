import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
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

  /// Lists [path] off the UI isolate. Listing + stat for every child runs
  /// with synchronous I/O inside a worker isolate, which is many times faster
  /// than one async `stat` round-trip per entry and never janks the UI, even
  /// for folders holding tens of thousands of files.
  Stream<List<FileEntry>> list(String path, {required bool showHidden}) async* {
    final FileSystemEntityType type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.notFound) {
      throw NotFoundFailure(path: path);
    }
    final Object result = await _listInWorker(path, showHidden);
    if (result is Failure) throw result;
    final List<FileEntry> entries = result as List<FileEntry>;
    // Hand the list over in slices so the first rows paint immediately on
    // gigantic folders while the rest is merged in the next frames.
    if (entries.length <= AppConstants.listBatchSize * 4) {
      yield entries;
      return;
    }
    for (int i = 0; i < entries.length; i += AppConstants.listBatchSize * 4) {
      final int end = i + AppConstants.listBatchSize * 4;
      yield entries.sublist(i, end > entries.length ? entries.length : end);
    }
  }

  /// Kept static (and non-async) so the closure sent to the worker captures
  /// nothing but the two plain arguments.
  static Future<Object> _listInWorker(String path, bool showHidden) =>
      Isolate.run<Object>(() => _listGuarded(path, showHidden), debugName: 'list-dir');

  /// Runs inside the worker isolate. Errors are converted to [Failure]s there
  /// so only plain data crosses the isolate boundary.
  static Object _listGuarded(String path, bool showHidden) {
    try {
      return listSync(path, showHidden: showHidden);
    } catch (error) {
      return Failure.fromException(error, path: path);
    }
  }

  /// Synchronous directory listing. Only call from a worker isolate.
  static List<FileEntry> listSync(String path, {required bool showHidden}) {
    final List<FileEntry> out = <FileEntry>[];
    for (final FileSystemEntity entity in Directory(path).listSync(followLinks: false)) {
      final String name = p.basename(entity.path);
      if (!showHidden && name.startsWith('.')) continue;
      try {
        // FileStat.statSync follows links, so a link to a folder is shown as
        // a folder and a dangling link is skipped.
        final FileStat stat = FileStat.statSync(entity.path);
        if (stat.type == FileSystemEntityType.notFound) continue;
        out.add(entryFromStat(entity.path, stat, name: name));
      } catch (_) {
        // Unreadable entry – leave it out rather than fail the whole folder.
      }
    }
    return out;
  }

  /// Direct-child counts for many folders at once ("24 items"), computed in
  /// one worker isolate instead of one async listing per folder.
  Future<Map<String, int>> childCounts(List<String> folders, {required bool showHidden}) {
    if (folders.isEmpty) return Future<Map<String, int>>.value(const <String, int>{});
    return _childCountsInWorker(List<String>.of(folders), showHidden);
  }

  static Future<Map<String, int>> _childCountsInWorker(List<String> folders, bool showHidden) {
    return Isolate.run<Map<String, int>>(
      () {
        final Map<String, int> out = <String, int>{};
        for (final String folder in folders) {
          int n = 0;
          try {
            for (final FileSystemEntity e in Directory(folder).listSync(followLinks: false)) {
              if (!showHidden && p.basename(e.path).startsWith('.')) continue;
              n++;
            }
          } catch (_) {}
          out[folder] = n;
        }
        return out;
      },
      debugName: 'child-counts',
    );
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

  /// The subset of [paths] that still exists, checked in one worker isolate.
  Future<Set<String>> existing(List<String> paths) {
    if (paths.isEmpty) return Future<Set<String>>.value(<String>{});
    return _existingInWorker(List<String>.of(paths));
  }

  static Future<Set<String>> _existingInWorker(List<String> paths) {
    return Isolate.run<Set<String>>(
      () => <String>{
        for (final String path in paths)
          if (FileSystemEntity.typeSync(path, followLinks: false) != FileSystemEntityType.notFound)
            path,
      },
      debugName: 'exists-batch',
    );
  }

  /// Adds or removes the `.nomedia` marker that tells Android's media scanner
  /// (and therefore every gallery) to ignore [folder]. Returns the files below
  /// it so the caller can ask MediaStore to re-evaluate them.
  Future<List<String>> setNoMedia(String folder, {required bool hidden}) async {
    final File marker = File(p.join(folder, '.nomedia'));
    if (hidden) {
      if (!await marker.exists()) await marker.create();
    } else if (await marker.exists()) {
      await marker.delete();
    }
    final List<FileEntry> files = await flatten(folder);
    return <String>[
      for (final FileEntry f in files.take(4000))
        if (!f.name.startsWith('.')) f.path,
    ];
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

  /// Files up to this size are copied with the native `File.copy`
  /// (kernel `sendfile`), which is the fastest path available from Dart.
  static const int nativeCopyThreshold = 16 * 1024 * 1024;

  /// Buffer used for large files so progress, pause and cancel stay
  /// responsive while throughput stays close to the disk's limit.
  static const int largeCopyChunk = 4 * 1024 * 1024;

  /// Copies [source] to [destination] as fast as the storage allows and
  /// reports copied bytes so speed can be measured. Large files are copied
  /// in 4 MB slices and honour pause/cancel between slices; a partial
  /// destination is always removed on failure or cancellation.
  Future<void> copyFile(
    String source,
    String destination, {
    void Function(int bytesCopied)? onBytes,
    PauseGate? gate,
    CancelToken? cancelToken,
  }) async {
    final File src = File(source);
    final File dst = File(destination);
    final FileStat srcStat = await src.stat();
    if (srcStat.type == FileSystemEntityType.notFound) {
      throw NotFoundFailure(path: source);
    }
    await dst.parent.create(recursive: true);
    if (gate != null) await gate.wait();
    cancelToken?.throwIfCancelled();

    if (srcStat.size <= nativeCopyThreshold) {
      try {
        await src.copy(destination);
      } catch (_) {
        await _deleteQuietly(dst);
        rethrow;
      }
      onBytes?.call(srcStat.size);
    } else {
      RandomAccessFile? input;
      RandomAccessFile? output;
      try {
        input = await src.open();
        output = await dst.open(mode: FileMode.write);
        final Uint8List buffer = Uint8List(largeCopyChunk);
        while (true) {
          if (gate != null) await gate.wait();
          cancelToken?.throwIfCancelled();
          final int read = await input.readInto(buffer);
          if (read <= 0) break;
          await output.writeFrom(buffer, 0, read);
          onBytes?.call(read);
        }
        await output.flush();
        await output.close();
        output = null;
        await input.close();
        input = null;
      } catch (_) {
        try {
          await output?.close();
        } catch (_) {}
        try {
          await input?.close();
        } catch (_) {}
        await _deleteQuietly(dst);
        rethrow;
      }
    }
    try {
      await dst.setLastModified(srcStat.modified);
    } catch (_) {}
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
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
  /// totals and progress maths. Directories are not included. The walk runs
  /// with synchronous I/O in a worker isolate.
  Future<List<FileEntry>> flatten(String root, {CancelToken? cancelToken}) async {
    cancelToken?.throwIfCancelled();
    final FileStat rootStat = await FileStat.stat(root);
    if (rootStat.type == FileSystemEntityType.notFound) {
      throw NotFoundFailure(path: root);
    }
    if (rootStat.type != FileSystemEntityType.directory) {
      return <FileEntry>[entryFromStat(root, rootStat)];
    }
    return IsolateWorker.run<String, List<FileEntry>>(
      root,
      _flattenJob,
      cancelToken: cancelToken,
      debugName: 'flatten',
    );
  }

  static Future<List<FileEntry>> _flattenJob(String root, WorkerContext ctx) async {
    final List<FileEntry> out = <FileEntry>[];
    final List<String> stack = <String>[root];
    int visited = 0;
    while (stack.isNotEmpty) {
      if (++visited % 64 == 0) await ctx.checkpoint();
      final String dir = stack.removeLast();
      List<FileSystemEntity> children;
      try {
        children = Directory(dir).listSync(followLinks: false);
      } on FileSystemException {
        // Unreadable subfolder – skip it rather than abort the whole op.
        continue;
      }
      for (final FileSystemEntity e in children) {
        if (e is Directory) {
          stack.add(e.path);
        } else if (e is File) {
          try {
            out.add(entryFromStat(e.path, e.statSync()));
          } catch (_) {}
        }
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
