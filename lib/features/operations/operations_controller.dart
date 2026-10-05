import 'dart:async';

import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/data/services/operation_runner.dart';
import 'package:filevault/domain/models/archive_entry.dart';
import 'package:filevault/domain/models/file_operation.dart';
import 'package:filevault/domain/models/trash_item.dart';
import 'package:filevault/domain/models/vault_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Snapshot of the operation queue.
class OperationsState {
  const OperationsState({this.operations = const <FileOperation>[]});

  final List<FileOperation> operations;

  FileOperation? get active {
    for (final FileOperation op in operations) {
      if (op.status == OperationStatus.running || op.status == OperationStatus.paused) {
        return op;
      }
    }
    return null;
  }

  List<FileOperation> get queued =>
      operations.where((FileOperation o) => o.status == OperationStatus.queued).toList();

  List<FileOperation> get finished =>
      operations.where((FileOperation o) => o.status.isFinished).toList();

  bool get hasActivity => operations.any((FileOperation o) => o.status.isActive);

  OperationsState copyWith({List<FileOperation>? operations}) =>
      OperationsState(operations: operations ?? this.operations);
}

/// Fires once per finished operation so views can refresh.
final StreamProvider<FileOperation> operationFinishedProvider =
    StreamProvider<FileOperation>((Ref ref) {
  return ref.watch(operationsProvider.notifier).finishedStream;
});

final NotifierProvider<OperationsController, OperationsState> operationsProvider =
    NotifierProvider<OperationsController, OperationsState>(OperationsController.new);

/// Serial queue of file operations with pause / resume / cancel, conflict
/// resolution via the UI, and a foreground-service notification.
class OperationsController extends Notifier<OperationsState> {
  final Map<String, _Controls> _controls = <String, _Controls>{};
  final Map<String, OperationOptions> _options = <String, OperationOptions>{};
  final StreamController<FileOperation> _finished = StreamController<FileOperation>.broadcast();
  bool _draining = false;
  DateTime _lastNotification = DateTime.fromMillisecondsSinceEpoch(0);

  /// Installed by the root widget; shows the conflict dialog.
  ConflictResolver? conflictResolver;

  /// Localised labels supplied by the UI layer for notifications.
  String Function(FileOperation op)? notificationTitle;

  Stream<FileOperation> get finishedStream => _finished.stream;

  @override
  OperationsState build() {
    ref.onDispose(_finished.close);
    return const OperationsState();
  }

  OperationRunner get _runner => OperationRunner(
        fs: ref.read(fileSystemServiceProvider),
        trash: ref.read(trashRepositoryProvider),
        archive: ref.read(archiveRepositoryProvider),
        vault: ref.read(vaultRepositoryProvider),
        index: ref.read(indexRepositoryProvider),
        collections: ref.read(collectionsRepositoryProvider),
      );

  // ------------------------------------------------------------ enqueue

  String enqueueCopy(List<String> sources, String destination) =>
      _enqueue(OperationType.copy, sources, destination: destination);

  String enqueueMove(List<String> sources, String destination) =>
      _enqueue(OperationType.move, sources, destination: destination);

  String enqueueTrash(List<String> paths) => _enqueue(OperationType.trash, paths);

  String enqueueDelete(List<String> paths) => _enqueue(OperationType.delete, paths);

  String enqueueRestore(List<TrashItem> items) => _enqueue(
        OperationType.restore,
        items.map((TrashItem i) => i.trashPath).toList(),
        options: OperationOptions(trashItems: items),
      );

  String enqueueCompress(
    List<String> sources,
    String archivePath, {
    ArchiveFormat format = ArchiveFormat.zip,
    int level = 6,
    String? password,
    bool deleteSources = false,
  }) =>
      _enqueue(
        OperationType.compress,
        sources,
        destination: archivePath,
        label: p.basename(archivePath),
        options: OperationOptions(
          archiveFormat: format,
          compressionLevel: level,
          password: password,
          deleteSourcesAfterArchive: deleteSources,
        ),
      );

  String enqueueExtract(
    String archivePath,
    String destinationDir, {
    List<String>? entries,
    String? password,
  }) =>
      _enqueue(
        OperationType.extract,
        <String>[archivePath],
        destination: destinationDir,
        label: p.basename(archivePath),
        options: OperationOptions(archiveEntries: entries, password: password),
      );

  String enqueueEncrypt(List<String> sources) => _enqueue(OperationType.encrypt, sources);

  String enqueueDecrypt(List<VaultItem> items, {String? destinationDir}) => _enqueue(
        OperationType.decrypt,
        items.map((VaultItem i) => i.storedName).toList(),
        destination: destinationDir,
        options: OperationOptions(vaultItems: items),
      );

  String _enqueue(
    OperationType type,
    List<String> sources, {
    String? destination,
    String? label,
    OperationOptions options = const OperationOptions(),
  }) {
    final String id = const Uuid().v4();
    final FileOperation op = FileOperation(
      id: id,
      type: type,
      sources: List<String>.unmodifiable(sources),
      destination: destination,
      createdAt: DateTime.now(),
      label: label,
    );
    _options[id] = options;
    _controls[id] = _Controls();
    state = state.copyWith(operations: <FileOperation>[...state.operations, op]);
    unawaited(_drain());
    return id;
  }

  // ------------------------------------------------------------ control

  void pause(String id) {
    _controls[id]?.gate.pause();
    _patch(id, (FileOperation o) => o.copyWith(status: OperationStatus.paused));
  }

  void resume(String id) {
    _controls[id]?.gate.resume();
    _patch(id, (FileOperation o) => o.copyWith(status: OperationStatus.running));
  }

  void cancel(String id) {
    final _Controls? c = _controls[id];
    if (c == null) return;
    c.cancel.cancel();
    c.gate.resume();
    final FileOperation? op = _find(id);
    if (op != null && op.status == OperationStatus.queued) {
      _patch(id, (FileOperation o) => o.copyWith(status: OperationStatus.cancelled, finishedAt: DateTime.now()));
      _controls.remove(id);
      _options.remove(id);
    }
  }

  void dismiss(String id) {
    final FileOperation? op = _find(id);
    if (op == null || op.status.isActive) return;
    state = state.copyWith(
      operations: state.operations.where((FileOperation o) => o.id != id).toList(),
    );
  }

  void clearFinished() {
    state = state.copyWith(
      operations: state.operations.where((FileOperation o) => o.status.isActive).toList(),
    );
  }

  // ------------------------------------------------------------- engine

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (true) {
        FileOperation? next;
        for (final FileOperation op in state.operations) {
          if (op.status == OperationStatus.queued) {
            next = op;
            break;
          }
        }
        if (next == null) break;
        await _execute(next);
      }
    } finally {
      _draining = false;
      await ref.read(platformChannelProvider).stopOperationNotification();
    }
  }

  Future<void> _execute(FileOperation op) async {
    final _Controls controls = _controls[op.id] ?? _Controls();
    final OperationOptions options = _options[op.id] ?? const OperationOptions();
    _patch(op.id, (FileOperation o) => o.copyWith(status: OperationStatus.running));
    await ref.read(platformChannelProvider).startOperationNotification(
          title: _title(op),
          text: _text(op),
          progress: 0,
        );

    final FileOperation result = await _runner.run(
      op.copyWith(status: OperationStatus.running),
      options: options,
      gate: controls.gate,
      cancelToken: controls.cancel,
      resolveConflict: conflictResolver,
      onUpdate: (FileOperation updated) {
        final FileOperation? current = _find(op.id);
        // Keep the paused flag the user set while the runner reports.
        final OperationStatus status =
            current?.status == OperationStatus.paused ? OperationStatus.paused : updated.status;
        _patch(op.id, (FileOperation _) => updated.copyWith(status: status));
        _notify(updated.copyWith(status: status));
      },
    );

    _patch(op.id, (FileOperation _) => result);
    _controls.remove(op.id);
    _options.remove(op.id);
    await ref.read(collectionsRepositoryProvider).recordOperation(result);
    await ref.read(platformChannelProvider).finishOperationNotification(
          title: _title(result),
          text: result.status == OperationStatus.completed
              ? '${result.processedFiles} / ${result.totalFiles}'
              : result.status.name,
        );
    if (!_finished.isClosed) _finished.add(result);
  }

  void _notify(FileOperation op) {
    final DateTime now = DateTime.now();
    if (now.difference(_lastNotification).inMilliseconds < 700) return;
    _lastNotification = now;
    unawaited(ref.read(platformChannelProvider).updateOperationNotification(
          title: _title(op),
          text: _text(op),
          progress: op.percent,
        ));
  }

  String _title(FileOperation op) =>
      notificationTitle?.call(op) ?? '${op.type.name} ${op.totalFiles} files';

  String _text(FileOperation op) {
    final String file = op.currentFile ?? '';
    return '${op.percent}% • ${op.processedFiles}/${op.totalFiles}${file.isEmpty ? '' : ' • $file'}';
  }

  FileOperation? _find(String id) {
    for (final FileOperation o in state.operations) {
      if (o.id == id) return o;
    }
    return null;
  }

  void _patch(String id, FileOperation Function(FileOperation) update) {
    state = state.copyWith(
      operations: <FileOperation>[
        for (final FileOperation o in state.operations) o.id == id ? update(o) : o,
      ],
    );
  }
}

class _Controls {
  final PauseGate gate = PauseGate();
  final CancelToken cancel = CancelToken();
}
