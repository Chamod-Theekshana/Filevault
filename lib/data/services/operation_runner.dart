import 'dart:io';
import 'dart:typed_data';

import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/data/services/file_system_service.dart';
import 'package:filevault/data/services/thumbnail_service.dart';
import 'package:filevault/domain/models/archive_entry.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/file_operation.dart';
import 'package:filevault/domain/models/trash_item.dart';
import 'package:filevault/domain/models/vault_item.dart';
import 'package:filevault/domain/repositories/archive_repository.dart';
import 'package:filevault/domain/repositories/collections_repository.dart';
import 'package:filevault/domain/repositories/index_repository.dart';
import 'package:filevault/domain/repositories/trash_repository.dart';
import 'package:filevault/domain/repositories/vault_repository.dart';
import 'package:path/path.dart' as p;

typedef ConflictResolver = Future<ConflictDecision?> Function(ConflictInfo info);
typedef OperationListener = void Function(FileOperation operation);

/// Tells the platform media index (MediaStore) which paths appeared and which
/// disappeared, so galleries and other apps never show stale or hidden files.
typedef MediaSync = Future<void> Function({
  required List<String> added,
  required List<String> removed,
});

/// Extra parameters some operations need beyond sources/destination.
class OperationOptions {
  const OperationOptions({
    this.archiveFormat = ArchiveFormat.zip,
    this.compressionLevel = 6,
    this.password,
    this.deleteSourcesAfterArchive = false,
    this.archiveEntries,
    this.trashItems = const <TrashItem>[],
    this.vaultItems = const <VaultItem>[],
    this.vaultKey,
  });

  final ArchiveFormat archiveFormat;
  final int compressionLevel;
  final String? password;
  final bool deleteSourcesAfterArchive;
  final List<String>? archiveEntries;
  final List<TrashItem> trashItems;
  final List<VaultItem> vaultItems;

  /// Copy of the Secure Folder key taken when a vault transfer was queued,
  /// so it can still run after the user has left (and locked) the vault.
  /// Wiped by the runner when the operation ends.
  final Uint8List? vaultKey;
}

/// Executes one [FileOperation] from start to finish. Pure orchestration –
/// the queue, notifications and UI live in the operations controller.
class OperationRunner {
  OperationRunner({
    required FileSystemService fs,
    required TrashRepository trash,
    required ArchiveRepository archive,
    required VaultRepository vault,
    required IndexRepository index,
    required CollectionsRepository collections,
    MediaSync? mediaSync,
    ThumbnailService? thumbnails,
  })  : _fs = fs,
        _trash = trash,
        _archive = archive,
        _vault = vault,
        _index = index,
        _collections = collections,
        _mediaSync = mediaSync,
        _thumbnails = thumbnails;

  final FileSystemService _fs;
  final TrashRepository _trash;
  final ArchiveRepository _archive;
  final VaultRepository _vault;
  final IndexRepository _index;
  final CollectionsRepository _collections;
  final MediaSync? _mediaSync;
  final ThumbnailService? _thumbnails;

  /// Media-index changes collected while an operation runs and flushed once
  /// at the end (also when it fails or is cancelled halfway).
  final List<String> _added = <String>[];
  final List<String> _removed = <String>[];

  static const int _maxMediaPaths = 4000;

  void _noteAdded(String path) {
    if (_added.length < _maxMediaPaths) _added.add(path);
  }

  void _noteRemoved(String path) {
    if (_removed.length < _maxMediaPaths) _removed.add(path);
  }

  Future<void> _flushMedia() async {
    final MediaSync? sync = _mediaSync;
    if (sync == null || (_added.isEmpty && _removed.isEmpty)) return;
    final List<String> added = List<String>.of(_added);
    final List<String> removed = List<String>.of(_removed);
    _added.clear();
    _removed.clear();
    try {
      await sync(added: added, removed: removed);
    } catch (_) {
      // Best effort: the gallery catches up on its next scan anyway.
    }
  }

  Future<FileOperation> run(
    FileOperation op, {
    required OperationOptions options,
    required PauseGate gate,
    required CancelToken cancelToken,
    required OperationListener onUpdate,
    ConflictResolver? resolveConflict,
  }) async {
    final _Ticker ticker = _Ticker(op, onUpdate);
    try {
      final FileOperation result = switch (op.type) {
        OperationType.copy => await _copyOrMove(op, ticker, gate, cancelToken, resolveConflict, move: false),
        OperationType.move => await _copyOrMove(op, ticker, gate, cancelToken, resolveConflict, move: true),
        OperationType.trash => await _trashAll(op, ticker, cancelToken),
        OperationType.delete => await _deleteAll(op, ticker, cancelToken),
        OperationType.restore => await _restoreAll(op, ticker, options, cancelToken),
        OperationType.compress => await _compress(op, ticker, options, cancelToken),
        OperationType.extract => await _extract(op, ticker, options, cancelToken),
        OperationType.encrypt => await _encrypt(op, ticker, options, cancelToken),
        OperationType.decrypt => await _decrypt(op, ticker, options, cancelToken),
      };
      return result.copyWith(
        status: OperationStatus.completed,
        finishedAt: DateTime.now(),
        bytesPerSecond: 0,
      );
    } on CancelledFailure {
      return ticker.current.copyWith(
        status: OperationStatus.cancelled,
        finishedAt: DateTime.now(),
        bytesPerSecond: 0,
      );
    } catch (error) {
      final Failure failure = Failure.fromException(error);
      return ticker.current.copyWith(
        status: OperationStatus.failed,
        errorMessage: _describe(failure),
        finishedAt: DateTime.now(),
        bytesPerSecond: 0,
      );
    } finally {
      await _flushMedia();
    }
  }

  static String _describe(Failure f) => switch (f) {
        PermissionFailure() => 'permission',
        NotFoundFailure() => 'notFound',
        DiskFullFailure() => 'diskFull',
        NameTooLongFailure() => 'nameTooLong',
        AlreadyExistsFailure() => 'exists',
        WrongPasswordFailure() => 'password',
        UnsupportedFormatFailure() => 'unsupported',
        CancelledFailure() => 'cancelled',
        VaultLockedFailure() => 'vaultLocked',
        _ => f.message ?? 'io',
      };

  // ----------------------------------------------------------- copy/move

  Future<FileOperation> _copyOrMove(
    FileOperation op,
    _Ticker ticker,
    PauseGate gate,
    CancelToken cancel,
    ConflictResolver? resolve, {
    required bool move,
  }) async {
    final String dest = op.destination!;
    if (!Directory(dest).existsSync()) throw NotFoundFailure(path: dest);
    for (final String src in op.sources) {
      if (p.dirname(src) == dest && move) throw const IoFailure(message: 'sameFolder');
      if (FileUtils.isWithin(src, dest) && Directory(src).existsSync()) {
        throw const IoFailure(message: 'intoItself');
      }
    }

    // Fast path first: a move on the same volume is a rename – a metadata
    // update that takes milliseconds no matter how big the item is. Those
    // items never need the (potentially slow) recursive pre-flight walk.
    final List<String> pending = <String>[];
    if (move) {
      ticker.set(totalFiles: op.sources.length);
      for (final String src in op.sources) {
        cancel.throwIfCancelled();
        await gate.wait();
        final String target = p.join(dest, p.basename(src));
        if (!_fs.existsSync(target) && FileSystemService.sameVolume(src, dest)) {
          ticker.current = ticker.current.copyWith(currentFile: p.basename(src));
          bool renamed = false;
          try {
            renamed = await _fs.tryRename(src, target);
          } on FileSystemException {
            renamed = false;
          }
          if (renamed) {
            ticker.add(files: 1);
            await _afterMove(src, target);
            _noteRemoved(src);
            _noteAdded(target);
            continue;
          }
        }
        pending.add(src);
      }
      if (pending.isEmpty) return ticker.current;
    } else {
      pending.addAll(op.sources);
    }

    // Pre-flight: totals for accurate progress (runs in a worker isolate).
    final List<_Planned> plan = <_Planned>[];
    for (final String src in pending) {
      cancel.throwIfCancelled();
      final List<FileEntry> files = await _fs.flatten(src, cancelToken: cancel);
      plan.add(_Planned(src, files));
    }
    final int renamedCount = ticker.current.processedFiles;
    final int totalFiles =
        renamedCount + plan.fold(0, (int a, _Planned b) => a + b.files.length);
    final int totalBytes =
        plan.fold(0, (int a, _Planned b) => a + b.files.fold(0, (int x, FileEntry f) => x + f.size));
    ticker.set(totalFiles: totalFiles, totalBytes: totalBytes);

    ConflictDecision? forAll;
    int remainingFiles = totalFiles - renamedCount;

    for (final _Planned item in plan) {
      cancel.throwIfCancelled();
      await gate.wait();
      final String src = item.source;
      final bool isDir = Directory(src).existsSync();
      final String target = p.join(dest, p.basename(src));

      if (isDir) {
        await Directory(target).create(recursive: true);
        bool skippedAny = false;
        for (final FileEntry f in item.files) {
          cancel.throwIfCancelled();
          await gate.wait();
          final String rel = p.relative(f.path, from: src);
          String fileTarget = p.join(target, rel);
          final _Verdict verdict = await _resolve(f, fileTarget, forAll, resolve, remainingFiles - 1);
          forAll = verdict.forAll;
          remainingFiles--;
          if (verdict.skip) {
            // Leave the source alone so a skipped file is never destroyed.
            skippedAny = true;
            ticker.add(bytes: f.size, files: 1);
            continue;
          }
          fileTarget = verdict.target;
          ticker.current = ticker.current.copyWith(currentFile: f.name);
          await _fs.copyFile(f.path, fileTarget,
              onBytes: (int n) => ticker.add(bytes: n), gate: gate, cancelToken: cancel);
          ticker.add(files: 1);
          _noteAdded(fileTarget);
          if (move) {
            await _fs.deleteEntity(f.path);
            _noteRemoved(f.path);
            // Per-file bookkeeping: when some files are skipped the tree is
            // only partially moved, so a whole-folder rewrite would be wrong.
            if (skippedAny) await _afterMove(f.path, fileTarget);
          }
        }
        // Recreate empty folders, then remove the emptied source tree.
        await _mirrorEmptyDirs(src, target);
        if (move) {
          if (skippedAny) {
            // Skipped files stay where they are; drop the folders that are
            // now empty so no hollow tree is left behind.
            await _pruneEmptyDirs(src);
          } else {
            await _fs.deleteEntity(src);
            await _afterMove(src, target);
          }
        } else {
          await _afterCopy(target);
        }
      } else {
        final FileEntry f = item.files.first;
        final _Verdict verdict = await _resolve(f, target, forAll, resolve, remainingFiles - 1);
        forAll = verdict.forAll;
        remainingFiles--;
        if (verdict.skip) {
          ticker.add(bytes: f.size, files: 1);
          continue;
        }
        ticker.current = ticker.current.copyWith(currentFile: f.name);
        await _fs.copyFile(f.path, verdict.target,
            onBytes: (int n) => ticker.add(bytes: n), gate: gate, cancelToken: cancel);
        ticker.add(files: 1);
        _noteAdded(verdict.target);
        if (move) {
          await _fs.deleteEntity(f.path);
          _noteRemoved(f.path);
          await _afterMove(f.path, verdict.target);
        } else {
          await _afterCopy(verdict.target);
        }
      }
    }
    return ticker.current;
  }

  Future<_Verdict> _resolve(
    FileEntry source,
    String target,
    ConflictDecision? forAll,
    ConflictResolver? resolve,
    int remaining,
  ) async {
    if (!_fs.existsSync(target)) return _Verdict(target, forAll: forAll);
    ConflictDecision? decision = forAll;
    if (decision == null) {
      if (resolve == null) {
        decision = const ConflictDecision(ConflictResolution.keepBoth);
      } else {
        final FileStat existing = await FileStat.stat(target);
        decision = await resolve(ConflictInfo(
          sourcePath: source.path,
          destinationPath: target,
          sourceSize: source.size,
          destinationSize: existing.size,
          sourceModified: source.modified,
          destinationModified: existing.modified,
          remaining: remaining,
        ));
        if (decision == null) throw const CancelledFailure();
      }
    }
    final ConflictDecision? nextForAll = decision.applyToAll ? decision : forAll;
    switch (decision.resolution) {
      case ConflictResolution.skip:
        return _Verdict(target, skip: true, forAll: nextForAll);
      case ConflictResolution.replace:
        await _fs.deleteEntity(target);
        return _Verdict(target, forAll: nextForAll);
      case ConflictResolution.keepBoth:
        return _Verdict(FileUtils.uniquePathSync(target), forAll: nextForAll);
    }
  }

  Future<void> _mirrorEmptyDirs(String src, String target) async {
    final List<String> stack = <String>[src];
    while (stack.isNotEmpty) {
      final String dir = stack.removeLast();
      try {
        await for (final FileSystemEntity e in Directory(dir).list(followLinks: false)) {
          if (e is Directory) {
            stack.add(e.path);
            final String rel = p.relative(e.path, from: src);
            await Directory(p.join(target, rel)).create(recursive: true);
          }
        }
      } catch (_) {}
    }
  }

  /// Removes directories under [root] (and [root] itself) that hold nothing,
  /// deepest first. Folders that still contain skipped files are kept.
  Future<void> _pruneEmptyDirs(String root) async {
    final List<String> dirs = <String>[];
    final List<String> stack = <String>[root];
    while (stack.isNotEmpty) {
      final String dir = stack.removeLast();
      dirs.add(dir);
      try {
        await for (final FileSystemEntity e in Directory(dir).list(followLinks: false)) {
          if (e is Directory) stack.add(e.path);
        }
      } catch (_) {}
    }
    for (final String dir in dirs.reversed) {
      try {
        if (Directory(dir).listSync(followLinks: false).isEmpty) {
          Directory(dir).deleteSync();
        }
      } catch (_) {}
    }
  }

  Future<void> _afterMove(String oldPath, String newPath) async {
    await _collections.pathMoved(oldPath, newPath);
    await _index.movePath(oldPath, newPath);
  }

  Future<void> _afterCopy(String newPath) async {
    try {
      final FileEntry e = await _fs.stat(newPath);
      await _index.upsertEntries(<FileEntry>[e]);
    } catch (_) {}
  }

  // ------------------------------------------------------- trash/delete

  Future<FileOperation> _trashAll(FileOperation op, _Ticker ticker, CancelToken cancel) async {
    ticker.set(totalFiles: op.sources.length);
    for (final String path in op.sources) {
      cancel.throwIfCancelled();
      ticker.current = ticker.current.copyWith(currentFile: p.basename(path));
      final Result<TrashItem> r = await _trash.moveToTrash(path);
      final Failure? f = r.failureOrNull;
      if (f != null) throw f;
      await _collections.pathDeleted(path);
      await _index.removePath(path);
      _noteRemoved(path);
      ticker.add(files: 1);
    }
    return ticker.current;
  }

  Future<FileOperation> _deleteAll(FileOperation op, _Ticker ticker, CancelToken cancel) async {
    ticker.set(totalFiles: op.sources.length);
    for (final String path in op.sources) {
      cancel.throwIfCancelled();
      ticker.current = ticker.current.copyWith(currentFile: p.basename(path));
      await _fs.deleteEntity(path);
      await _collections.pathDeleted(path);
      await _index.removePath(path);
      _noteRemoved(path);
      ticker.add(files: 1);
    }
    return ticker.current;
  }

  Future<FileOperation> _restoreAll(
      FileOperation op, _Ticker ticker, OperationOptions options, CancelToken cancel) async {
    ticker.set(totalFiles: options.trashItems.length);
    for (final TrashItem item in options.trashItems) {
      cancel.throwIfCancelled();
      ticker.current = ticker.current.copyWith(currentFile: item.name);
      final Result<String> r = await _trash.restore(item);
      final Failure? f = r.failureOrNull;
      if (f != null) throw f;
      await _afterCopy(r.valueOrNull!);
      _noteAdded(r.valueOrNull!);
      ticker.add(files: 1);
    }
    return ticker.current;
  }

  // ------------------------------------------------------------ archives

  Future<FileOperation> _compress(
      FileOperation op, _Ticker ticker, OperationOptions options, CancelToken cancel) async {
    int totalBytes = 0;
    int totalFiles = 0;
    for (final String src in op.sources) {
      final List<FileEntry> files = await _fs.flatten(src, cancelToken: cancel);
      totalFiles += files.length;
      totalBytes += files.fold(0, (int a, FileEntry f) => a + f.size);
    }
    ticker.set(totalFiles: totalFiles, totalBytes: totalBytes);
    final Result<void> r = await _archive.create(
      op.destination!,
      op.sources,
      format: options.archiveFormat,
      level: options.compressionLevel,
      password: options.password,
      cancelToken: cancel,
      onProgress: (double f, String? label) => ticker.fraction(f, label),
    );
    final Failure? failure = r.failureOrNull;
    if (failure != null) throw failure;
    await _afterCopy(op.destination!);
    if (options.deleteSourcesAfterArchive) {
      for (final String src in op.sources) {
        await _fs.deleteEntity(src);
        await _collections.pathDeleted(src);
        await _index.removePath(src);
      }
    }
    return ticker.current.copyWith(processedFiles: totalFiles, processedBytes: totalBytes);
  }

  Future<FileOperation> _extract(
      FileOperation op, _Ticker ticker, OperationOptions options, CancelToken cancel) async {
    final String archive = op.sources.first;
    ticker.set(totalBytes: File(archive).existsSync() ? File(archive).lengthSync() : 0);
    final Result<int> r = await _archive.extract(
      archive,
      op.destination!,
      entryPaths: options.archiveEntries,
      password: options.password,
      cancelToken: cancel,
      onProgress: (double f, String? label) => ticker.fraction(f, label),
    );
    final Failure? failure = r.failureOrNull;
    if (failure != null) throw failure;
    final int written = r.valueOrNull ?? 0;
    return ticker.current.copyWith(
      processedFiles: written,
      totalFiles: written,
      processedBytes: ticker.current.totalBytes,
    );
  }

  // --------------------------------------------------------------- vault

  /// Moves files – and whole folders – into the Secure Folder.
  ///
  /// * Takes a private copy of the master key so locking the vault screen
  ///   mid-transfer cannot break the operation; the copy is wiped at the end.
  /// * Folders are expanded into their files; every file keeps its original
  ///   path so "Move out" can rebuild the folder structure later.
  /// * One failing file does not abort the batch; the first failure is
  ///   reported once everything else has been secured.
  /// * Every secured original is removed from MediaStore and from the
  ///   thumbnail cache so it cannot surface in galleries or other apps.
  Future<FileOperation> _encrypt(
      FileOperation op, _Ticker ticker, OperationOptions options, CancelToken cancel) async {
    final Uint8List? key = options.vaultKey ?? _vault.sessionKey();
    if (key == null) throw const VaultLockedFailure(secondsRemaining: 0);
    try {
      final List<FileEntry> files = <FileEntry>[];
      final List<String> folderRoots = <String>[];
      for (final String src in op.sources) {
        cancel.throwIfCancelled();
        final FileStat stat = await FileStat.stat(src);
        if (stat.type == FileSystemEntityType.directory) {
          folderRoots.add(src);
          files.addAll(await _fs.flatten(src, cancelToken: cancel));
        } else if (stat.type == FileSystemEntityType.file) {
          files.add(FileSystemService.entryFromStat(src, stat));
        }
      }
      final int totalBytes = files.fold(0, (int a, FileEntry f) => a + f.size);
      ticker.set(totalFiles: files.length, totalBytes: totalBytes);

      int doneBytes = 0;
      Failure? firstFailure;
      for (final FileEntry f in files) {
        cancel.throwIfCancelled();
        ticker.current = ticker.current.copyWith(currentFile: f.name);
        final int base = doneBytes;
        final Result<VaultItem> r = await _vault.addFile(
          f.path,
          key: key,
          cancelToken: cancel,
          onProgress: (double fraction, String? _) =>
              ticker.setBytes(base + (f.size * fraction).round()),
        );
        final Failure? failure = r.failureOrNull;
        if (failure is CancelledFailure) throw failure;
        doneBytes += f.size;
        ticker.setBytes(doneBytes);
        ticker.add(files: 1);
        if (failure != null) {
          firstFailure ??= failure;
          continue;
        }
        _noteRemoved(f.path);
        await _thumbnails?.evict(f.path, size: f.size, modified: f.modified);
        await _collections.pathDeleted(f.path);
        await _index.removePath(f.path);
      }
      for (final String root in folderRoots) {
        await _pruneEmptyDirs(root);
        if (!_fs.existsSync(root)) {
          _noteRemoved(root);
          await _collections.pathDeleted(root);
          await _index.removePath(root);
        }
      }
      if (firstFailure != null) throw firstFailure;
      return ticker.current;
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }

  Future<FileOperation> _decrypt(
      FileOperation op, _Ticker ticker, OperationOptions options, CancelToken cancel) async {
    final Uint8List? key = options.vaultKey ?? _vault.sessionKey();
    if (key == null) throw const VaultLockedFailure(secondsRemaining: 0);
    try {
      final int totalBytes = options.vaultItems.fold(0, (int a, VaultItem b) => a + b.size);
      ticker.set(totalFiles: options.vaultItems.length, totalBytes: totalBytes);
      int doneBytes = 0;
      for (final VaultItem item in options.vaultItems) {
        cancel.throwIfCancelled();
        ticker.current = ticker.current.copyWith(currentFile: item.name);
        final int base = doneBytes;
        final Result<String> r = await _vault.exportItem(
          item,
          destinationDir: op.destination,
          key: key,
          cancelToken: cancel,
          onProgress: (double fraction, String? _) =>
              ticker.setBytes(base + (item.size * fraction).round()),
        );
        final Failure? failure = r.failureOrNull;
        if (failure != null) throw failure;
        doneBytes += item.size;
        ticker.setBytes(doneBytes);
        ticker.add(files: 1);
        _noteAdded(r.valueOrNull!);
        await _afterCopy(r.valueOrNull!);
      }
      return ticker.current;
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }
}

class _Planned {
  const _Planned(this.source, this.files);
  final String source;
  final List<FileEntry> files;
}

class _Verdict {
  const _Verdict(this.target, {this.skip = false, this.forAll});
  final String target;
  final bool skip;
  final ConflictDecision? forAll;
}

/// Accumulates progress and throttles notifications to ~10/s while keeping
/// a rolling transfer-speed estimate.
class _Ticker {
  _Ticker(this.current, this._listener) : _started = DateTime.now();

  FileOperation current;
  final OperationListener _listener;
  final DateTime _started;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
  final List<(DateTime, int)> _samples = <(DateTime, int)>[];

  void set({int? totalFiles, int? totalBytes}) {
    current = current.copyWith(
      totalFiles: totalFiles,
      totalBytes: totalBytes,
      status: OperationStatus.running,
    );
    _emit(force: true);
  }

  void add({int bytes = 0, int files = 0}) {
    current = current.copyWith(
      processedBytes: current.processedBytes + bytes,
      processedFiles: current.processedFiles + files,
    );
    // Throttled even for file ticks: copying thousands of small files must
    // not rebuild the UI thousands of times.
    _emit();
  }

  void setBytes(int bytes) {
    current = current.copyWith(processedBytes: bytes);
    _emit();
  }

  void fraction(double f, String? label) {
    current = current.copyWith(
      processedBytes: (current.totalBytes * f).round(),
      currentFile: label,
    );
    _emit(force: f >= 1);
  }

  void _emit({bool force = false}) {
    final DateTime now = DateTime.now();
    if (!force && now.difference(_lastEmit).inMilliseconds < 100) return;
    _lastEmit = now;
    _samples.add((now, current.processedBytes));
    while (_samples.length > 1 &&
        now.difference(_samples.first.$1).inMilliseconds > 3000) {
      _samples.removeAt(0);
    }
    double speed = 0;
    if (_samples.length >= 2) {
      final (DateTime, int) first = _samples.first;
      final int ms = now.difference(first.$1).inMilliseconds;
      if (ms > 0) speed = (current.processedBytes - first.$2) * 1000 / ms;
    } else {
      final int ms = now.difference(_started).inMilliseconds;
      if (ms > 0) speed = current.processedBytes * 1000 / ms;
    }
    current = current.copyWith(bytesPerSecond: speed);
    _listener(current);
  }
}
