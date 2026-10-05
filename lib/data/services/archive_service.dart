import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/domain/models/archive_entry.dart';
import 'package:path/path.dart' as p;

/// Pure-Dart archive engine (ZIP, TAR, GZ, BZ2, XZ). Every public method
/// hands the work to a worker isolate.
class ArchiveService {
  const ArchiveService();

  static const Set<String> _readable = <String>{
    'zip', 'jar', 'tar', 'gz', 'tgz', 'bz2', 'xz',
  };

  bool canOpen(String path) {
    final String lower = path.toLowerCase();
    final int dot = lower.lastIndexOf('.');
    if (dot < 0) return false;
    return _readable.contains(lower.substring(dot + 1));
  }

  Future<List<ArchiveEntryInfo>> listEntries(String path, {String? password}) async {
    final List<Object?> raw = await IsolateWorker.run<Map<String, Object?>, List<Object?>>(
      <String, Object?>{'path': path, 'password': password},
      _listJob,
      debugName: 'archive-list',
    );
    return raw
        .whereType<Map<String, Object?>>()
        .map(ArchiveEntryInfo.fromMap)
        .toList(growable: false);
  }

  Future<int> extract(
    String archivePath,
    String destinationDir, {
    List<String>? entryPaths,
    String? password,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    return IsolateWorker.run<Map<String, Object?>, int>(
      <String, Object?>{
        'path': archivePath,
        'dest': destinationDir,
        'entries': entryPaths,
        'password': password,
      },
      _extractJob,
      onProgress: onProgress,
      cancelToken: cancelToken,
      debugName: 'archive-extract',
    );
  }

  Future<void> create(
    String archivePath,
    List<String> sources, {
    ArchiveFormat format = ArchiveFormat.zip,
    int level = 6,
    String? password,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    return IsolateWorker.run<Map<String, Object?>, void>(
      <String, Object?>{
        'path': archivePath,
        'sources': sources,
        'format': format.name,
        'level': level,
        'password': password,
      },
      _createJob,
      onProgress: onProgress,
      cancelToken: cancelToken,
      debugName: 'archive-create',
    );
  }

  // ------------------------------------------------------- isolate jobs

  /// Maps a thrown decoding/extraction error onto a typed [Failure].
  ///
  /// The `archive` package reports a wrong or missing password in several
  /// ways (a plain `Exception('password error')`, a failed null-check on the
  /// stored password, or a CRC mismatch), so classification is by message.
  static Failure _classify(Object error, String path) {
    if (error is Failure) return error;
    final String message = error.toString().toLowerCase();
    if (message.contains('password') ||
        message.contains('encrypt') ||
        message.contains('null check operator') ||
        message.contains('invalid checksum') ||
        message.contains('crc')) {
      return const WrongPasswordFailure();
    }
    return IoFailure(path: path, message: error.toString());
  }

  static bool _isZip(String lower) => lower.endsWith('.zip') || lower.endsWith('.jar');

  static Archive _decode(String path, String? password) {
    final String lower = path.toLowerCase();
    final Uint8List bytes;
    try {
      bytes = File(path).readAsBytesSync();
    } catch (error) {
      throw Failure.fromException(error, path: path);
    }
    try {
      if (_isZip(lower)) {
        return ZipDecoder().decodeBytes(bytes, password: password);
      }
      if (lower.endsWith('.tar')) {
        return TarDecoder().decodeBytes(bytes);
      }
      if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
        return TarDecoder().decodeBytes(const GZipDecoder().decodeBytes(bytes));
      }
      if (lower.endsWith('.tar.bz2')) {
        return TarDecoder().decodeBytes(BZip2Decoder().decodeBytes(bytes));
      }
      if (lower.endsWith('.tar.xz')) {
        return TarDecoder().decodeBytes(XZDecoder().decodeBytes(bytes));
      }
      // Single-file compressed streams expose one entry named after the file.
      if (lower.endsWith('.gz')) {
        return _single(path, const GZipDecoder().decodeBytes(bytes), '.gz');
      }
      if (lower.endsWith('.bz2')) {
        return _single(path, BZip2Decoder().decodeBytes(bytes), '.bz2');
      }
      if (lower.endsWith('.xz')) {
        return _single(path, XZDecoder().decodeBytes(bytes), '.xz');
      }
    } catch (error) {
      throw _classify(error, path);
    }
    throw const UnsupportedFormatFailure();
  }

  /// Reads one small entry to find out whether the archive needs a password.
  /// Listing an encrypted ZIP succeeds (names are not encrypted), so without
  /// this probe the password prompt would only appear at extraction time.
  static void _probePassword(Archive archive, String path) {
    ArchiveFile? smallest;
    for (final ArchiveFile f in archive) {
      if (!f.isFile || f.size <= 0) continue;
      if (smallest == null || f.size < smallest.size) smallest = f;
    }
    if (smallest == null) return;
    try {
      smallest.readBytes();
    } catch (error) {
      throw _classify(error, path);
    }
  }

  /// ZIP stores a packed DOS timestamp in `lastModTime` while TAR stores Unix
  /// epoch seconds; pick whichever yields a plausible date.
  static DateTime? _entryDate(ArchiveFile file, bool isZip) {
    if (isZip) {
      try {
        final DateTime dos = file.lastModDateTime;
        if (dos.year >= 1980 && dos.year <= 2200) return dos;
      } catch (_) {}
      return null;
    }
    final int seconds = file.lastModTime;
    if (seconds <= 0) return null;
    final DateTime unix = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return unix.year >= 1970 && unix.year <= 2200 ? unix : null;
  }

  static Archive _single(String path, List<int> data, String suffix) {
    final String name = p.basename(path);
    final String inner = name.toLowerCase().endsWith(suffix)
        ? name.substring(0, name.length - suffix.length)
        : '$name.out';
    final Archive archive = Archive();
    archive.addFile(ArchiveFile.bytes(inner, Uint8List.fromList(data)));
    return archive;
  }

  static Future<List<Object?>> _listJob(Map<String, Object?> args, WorkerContext ctx) async {
    final String path = args['path']! as String;
    final String? password = args['password'] as String?;
    final Archive archive = _decode(path, password);
    final bool isZip = _isZip(path.toLowerCase());
    if (isZip) _probePassword(archive, path);
    final List<Object?> out = <Object?>[];
    final Set<String> seenDirs = <String>{};
    for (final ArchiveFile file in archive) {
      final String raw = file.name.replaceAll('\\', '/');
      final bool isDir = !file.isFile || raw.endsWith('/');
      final String clean = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
      if (clean.isEmpty) continue;
      // Make sure every parent folder exists as an entry, even when the
      // archive only lists files.
      final List<String> parts = clean.split('/');
      for (int i = 1; i < parts.length; i++) {
        final String dirPath = parts.take(i).join('/');
        if (seenDirs.add(dirPath)) {
          out.add(ArchiveEntryInfo(
            path: dirPath,
            name: parts[i - 1],
            isDirectory: true,
            size: 0,
          ).toMap());
        }
      }
      if (isDir) {
        if (seenDirs.add(clean)) {
          out.add(ArchiveEntryInfo(
            path: clean,
            name: parts.last,
            isDirectory: true,
            size: 0,
          ).toMap());
        }
        continue;
      }
      out.add(ArchiveEntryInfo(
        path: clean,
        name: parts.last,
        isDirectory: false,
        size: file.size,
        modified: _entryDate(file, isZip),
      ).toMap());
    }
    return out;
  }

  static Future<int> _extractJob(Map<String, Object?> args, WorkerContext ctx) async {
    final String path = args['path']! as String;
    final String dest = args['dest']! as String;
    final List<Object?>? wanted = args['entries'] as List<Object?>?;
    final Set<String>? filter = wanted?.map((Object? e) => e.toString()).toSet();
    final Archive archive = _decode(path, args['password'] as String?);

    final List<ArchiveFile> files = <ArchiveFile>[];
    for (final ArchiveFile f in archive) {
      final String clean = _cleanName(f.name);
      if (clean.isEmpty) continue;
      if (filter != null && !_matches(filter, clean)) continue;
      files.add(f);
    }
    final int totalBytes = files.fold(0, (int a, ArchiveFile f) => a + (f.isFile ? f.size : 0));
    int done = 0;
    int written = 0;
    Directory(dest).createSync(recursive: true);
    for (int i = 0; i < files.length; i++) {
      final ArchiveFile f = files[i];
      final String clean = _cleanName(f.name);
      final String target = p.normalize(p.join(dest, clean));
      // Zip-slip guard: never write outside the destination folder.
      if (!p.isWithin(dest, target) && target != dest) continue;
      if (!f.isFile) {
        Directory(target).createSync(recursive: true);
        continue;
      }
      ctx.report(totalBytes == 0 ? i / files.length : done / totalBytes, clean);
      final Uint8List? content;
      try {
        content = f.readBytes();
      } catch (error) {
        throw _classify(error, path);
      }
      if (content == null) continue;
      Directory(p.dirname(target)).createSync(recursive: true);
      File(target).writeAsBytesSync(content, flush: false);
      final DateTime? mod = _entryDate(f, _isZip(path.toLowerCase()));
      if (mod != null) {
        try {
          File(target).setLastModifiedSync(mod);
        } catch (_) {}
      }
      done += f.size;
      written++;
      if (i % 4 == 0) await ctx.checkpoint();
    }
    ctx.report(1);
    return written;
  }

  static bool _matches(Set<String> filter, String entryPath) {
    for (final String f in filter) {
      if (entryPath == f || entryPath.startsWith('$f/')) return true;
    }
    return false;
  }

  static String _cleanName(String raw) {
    String name = raw.replaceAll('\\', '/');
    while (name.startsWith('/')) {
      name = name.substring(1);
    }
    if (name.endsWith('/')) name = name.substring(0, name.length - 1);
    return name;
  }

  static Future<void> _createJob(Map<String, Object?> args, WorkerContext ctx) async {
    final String target = args['path']! as String;
    final List<String> sources =
        (args['sources']! as List<Object?>).map((Object? e) => e.toString()).toList();
    final String format = (args['format'] as String?) ?? 'zip';
    final int level = (args['level'] as int?) ?? 6;
    final String? password = args['password'] as String?;

    // Collect files first so progress can be byte-accurate.
    final List<_PlannedFile> planned = <_PlannedFile>[];
    final List<String> emptyDirs = <String>[];
    final Set<String> takenNames = <String>{};
    for (final String src in sources) {
      final FileSystemEntityType type = FileSystemEntity.typeSync(src, followLinks: false);
      if (type == FileSystemEntityType.directory) {
        // Two sources can share a basename; give each tree a unique root
        // inside the archive so neither overwrites the other.
        final String root = _uniqueEntryName(p.basename(src), takenNames);
        takenNames.add(root);
        final List<String> stack = <String>[src];
        while (stack.isNotEmpty) {
          final String dir = stack.removeLast();
          List<FileSystemEntity> children;
          try {
            children = Directory(dir).listSync(followLinks: false);
          } catch (_) {
            // Unreadable subfolder: skip it rather than abort the archive.
            continue;
          }
          if (children.isEmpty) emptyDirs.add(_under(root, dir, src));
          for (final FileSystemEntity e in children) {
            if (e is Directory) {
              stack.add(e.path);
            } else if (e is File) {
              try {
                planned.add(_PlannedFile(e.path, _under(root, e.path, src), e.lengthSync()));
              } catch (_) {}
            }
          }
        }
      } else if (type == FileSystemEntityType.file) {
        // Two sources can share a basename ("a/notes.txt", "b/notes.txt");
        // Archive.addFile replaces same-named entries, so de-duplicate here.
        final String unique = _uniqueEntryName(p.basename(src), takenNames);
        takenNames.add(unique);
        planned.add(_PlannedFile(src, unique, File(src).lengthSync()));
      }
    }
    final int totalBytes = planned.fold(0, (int a, _PlannedFile f) => a + f.size);

    final Archive archive = Archive();
    for (final String dir in emptyDirs) {
      archive.addFile(ArchiveFile.bytes('${dir.replaceAll('\\', '/')}/', Uint8List(0)));
    }
    int done = 0;
    for (int i = 0; i < planned.length; i++) {
      final _PlannedFile f = planned[i];
      ctx.report(totalBytes == 0 ? 0 : done / totalBytes * 0.7, f.relative);
      final Uint8List bytes = File(f.path).readAsBytesSync();
      final ArchiveFile entry = ArchiveFile.bytes(f.relative.replaceAll('\\', '/'), bytes);
      try {
        entry.lastModTime = File(f.path).lastModifiedSync().millisecondsSinceEpoch ~/ 1000;
      } catch (_) {}
      archive.addFile(entry);
      done += f.size;
      if (i % 4 == 0) await ctx.checkpoint();
    }

    ctx.report(0.75, p.basename(target));
    final List<int>? encoded;
    if (format == 'zip') {
      encoded = ZipEncoder(password: password).encodeBytes(archive, level: level);
    } else if (format == 'tarGz') {
      final List<int> tar = TarEncoder().encodeBytes(archive);
      encoded = const GZipEncoder().encodeBytes(tar, level: level);
    } else {
      encoded = TarEncoder().encodeBytes(archive);
    }
    await ctx.checkpoint();
    ctx.report(0.95, p.basename(target));
    final File out = File(target);
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(encoded ?? <int>[], flush: true);
    ctx.report(1);
  }
}

/// Path of [path] inside the archive: [root] plus its location under [from].
String _under(String root, String path, String from) {
  final String rel = p.relative(path, from: from);
  return rel == '.' ? root : p.join(root, rel);
}

/// "notes.txt" -> "notes (1).txt" when the name is already used.
String _uniqueEntryName(String name, Set<String> taken) {
  if (!taken.contains(name)) return name;
  final String ext = p.extension(name);
  final String stem = ext.isEmpty ? name : name.substring(0, name.length - ext.length);
  for (int i = 1; i < 1000; i++) {
    final String candidate = '$stem ($i)$ext';
    if (!taken.contains(candidate)) return candidate;
  }
  return '$stem-${DateTime.now().microsecondsSinceEpoch}$ext';
}

class _PlannedFile {
  const _PlannedFile(this.path, this.relative, this.size);
  final String path;
  final String relative;
  final int size;
}
