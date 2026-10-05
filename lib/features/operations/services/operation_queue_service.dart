import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/operation_task.dart';
import '../models/operation_queue_state.dart';
import '../models/conflict_resolution.dart';
import 'notification_service.dart';

final operationQueueProvider = StateNotifierProvider<OperationQueueService, OperationQueueState>((ref) {
  return OperationQueueService();
});

class OperationQueueService extends StateNotifier<OperationQueueState> {
  OperationQueueService() : super(const OperationQueueState());

  final _uuid = const Uuid();
  bool _isProcessing = false;
  
  // Controllers and state for current operation
  bool _isCancelled = false;
  bool _isPaused = false;
  Completer<void>? _pauseCompleter;
  Completer<ConflictResolution>? _conflictCompleter;
  bool _applyAllConflicts = false;
  ConflictResolution? _defaultConflictResolution;

  void toggleMinimize() {
    state = state.copyWith(isMinimized: !state.isMinimized);
  }

  void queueOperation(OperationType type, List<String> sourcePaths, {String? destinationPath}) {
    final task = OperationTask(
      id: _uuid.v4(),
      type: type,
      sourcePaths: sourcePaths,
      destinationPath: destinationPath,
    );
    state = state.copyWith(tasks: [...state.tasks, task]);
    _processQueue();
  }

  void pauseCurrent() {
    _isPaused = true;
    _pauseCompleter = Completer<void>();
    _updateCurrentTaskStatus(OperationStatus.paused);
  }

  void resumeCurrent() {
    _isPaused = false;
    if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
      _pauseCompleter!.complete();
    }
    _updateCurrentTaskStatus(OperationStatus.running);
  }

  void cancelCurrent() {
    _isCancelled = true;
    resumeCurrent(); // unpause if paused
    if (_conflictCompleter != null && !_conflictCompleter!.isCompleted) {
      _conflictCompleter!.complete(ConflictResolution.skip);
    }
    _updateCurrentTaskStatus(OperationStatus.cancelled);
  }

  void resolveConflict(ConflictResolution resolution, bool applyAll) {
    _applyAllConflicts = applyAll;
    if (applyAll) {
      _defaultConflictResolution = resolution;
    }
    if (_conflictCompleter != null && !_conflictCompleter!.isCompleted) {
      _conflictCompleter!.complete(resolution);
    }
  }

  void _updateCurrentTaskStatus(OperationStatus status) {
    final activeIndex = state.tasks.indexWhere((t) => t.id == state.currentActiveTask?.id);
    if (activeIndex != -1) {
      final updatedTask = state.tasks[activeIndex].copyWith(status: status);
      final newTasks = List<OperationTask>.from(state.tasks);
      newTasks[activeIndex] = updatedTask;
      state = state.copyWith(tasks: newTasks);
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    
    final nextTaskIndex = state.tasks.indexWhere((t) => t.status == OperationStatus.queued);
    if (nextTaskIndex == -1) return;

    _isProcessing = true;
    _isCancelled = false;
    _isPaused = false;
    _pauseCompleter = null;
    _conflictCompleter = null;
    _applyAllConflicts = false;
    _defaultConflictResolution = null;

    var task = state.tasks[nextTaskIndex].copyWith(status: OperationStatus.running);
    final newTasks = List<OperationTask>.from(state.tasks);
    newTasks[nextTaskIndex] = task;
    state = state.copyWith(tasks: newTasks);

    try {
      if (task.type == OperationType.copy) {
        await _executeCopyMove(task, isMove: false);
      } else if (task.type == OperationType.move) {
        await _executeCopyMove(task, isMove: true);
      } else if (task.type == OperationType.delete) {
        await _executeDelete(task);
      } else if (task.type == OperationType.rename) {
        await _executeRename(task);
      } else if (task.type == OperationType.create) {
        await _executeCreate(task);
      }
      
      if (!_isCancelled) {
        _updateTask(task.id, (t) => t.copyWith(status: OperationStatus.completed));
      }
    } catch (e) {
      _updateTask(task.id, (t) => t.copyWith(status: OperationStatus.error, errorMessage: e.toString()));
    }
    
    NotificationService().cancelNotification(1);

    _isProcessing = false;
    _processQueue(); // process next
  }

  void _updateTask(String id, OperationTask Function(OperationTask) update) {
    final idx = state.tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final newTasks = List<OperationTask>.from(state.tasks);
      newTasks[idx] = update(newTasks[idx]);
      state = state.copyWith(tasks: newTasks);
    }
  }

  Future<void> _executeDelete(OperationTask task) async {
    int totalFiles = task.sourcePaths.length;
    _updateTask(task.id, (t) => t.copyWith(totalFiles: totalFiles));

    int processed = 0;
    for (String path in task.sourcePaths) {
      await _checkPauseCancel();
      if (_isCancelled) break;

      final entity = FileSystemEntity.isDirectorySync(path) ? Directory(path) : File(path);
      if (entity.existsSync()) {
        await entity.delete(recursive: true);
      }
      processed++;
      _updateTask(task.id, (t) => t.copyWith(processedFiles: processed));
    }
  }

  Future<void> _executeRename(OperationTask task) async {
    if (task.destinationPath == null || task.sourcePaths.isEmpty) return;
    _updateTask(task.id, (t) => t.copyWith(totalFiles: 1));
    
    final source = task.sourcePaths.first;
    final dest = task.destinationPath!; 
    
    final entity = FileSystemEntity.isDirectorySync(source) ? Directory(source) : File(source);
    if (entity.existsSync()) {
      await entity.rename(dest);
    }
    _updateTask(task.id, (t) => t.copyWith(processedFiles: 1));
  }

  Future<void> _executeCreate(OperationTask task) async {
    if (task.destinationPath == null) return;
    _updateTask(task.id, (t) => t.copyWith(totalFiles: 1));
    
    final path = task.destinationPath!;
    if (p.extension(path).isEmpty) {
      await Directory(path).create(recursive: true);
    } else {
      await File(path).create(recursive: true);
    }
    _updateTask(task.id, (t) => t.copyWith(processedFiles: 1));
  }

  Future<void> _executeCopyMove(OperationTask task, {required bool isMove}) async {
    if (task.destinationPath == null) throw Exception("Destination path is required");
    
    // 1. Calculate totals
    int totalFiles = 0;
    int totalBytes = 0;
    
    for (String path in task.sourcePaths) {
      if (FileSystemEntity.isDirectorySync(path)) {
        final dir = Directory(path);
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalFiles++;
            totalBytes += await entity.length();
          }
        }
      } else {
        totalFiles++;
        totalBytes += await File(path).length();
      }
    }

    _updateTask(task.id, (t) => t.copyWith(totalFiles: totalFiles, totalBytes: totalBytes));

    int processedFiles = 0;
    int processedBytes = 0;
    
    final lastSpeedUpdate = Stopwatch()..start();
    int bytesSinceLastUpdate = 0;

    for (String source in task.sourcePaths) {
      await _checkPauseCancel();
      if (_isCancelled) break;

      final sourceName = p.basename(source);
      final destPath = p.join(task.destinationPath!, sourceName);
      
      // If same volume move (rename), we can do it instantly if it's a move
      if (isMove && _isSameVolume(source, destPath)) {
        await _handleConflictAndMove(source, destPath, task);
        // We consider it fully processed instantly
        if (FileSystemEntity.isDirectorySync(destPath)) {
          // Just approximate
        }
        continue;
      }
      
      // Otherwise deep copy
      if (FileSystemEntity.isDirectorySync(source)) {
        final dir = Directory(source);
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          await _checkPauseCancel();
          if (_isCancelled) break;

          final relativePath = p.relative(entity.path, from: source);
          final targetPath = p.join(destPath, relativePath);

          if (entity is Directory) {
            await Directory(targetPath).create(recursive: true);
          } else if (entity is File) {
            final copiedBytes = await _copyFileWithProgress(
              entity.path, targetPath, task, 
              onProgress: (bytes) {
                processedBytes += bytes;
                bytesSinceLastUpdate += bytes;
                
                if (lastSpeedUpdate.elapsedMilliseconds > 500) {
                  final speed = bytesSinceLastUpdate / (lastSpeedUpdate.elapsedMilliseconds / 1000);
                  _updateTask(task.id, (t) => t.copyWith(
                    processedBytes: processedBytes,
                    currentSpeedBytesPerSecond: speed,
                  ));
                  
                  // Show Notification
                  NotificationService().showProgressNotification(
                    id: 1, 
                    title: isMove ? 'Moving files...' : 'Copying files...', 
                    body: p.basename(entity.path), 
                    progress: processedBytes, 
                    maxProgress: totalBytes,
                  );
                  
                  bytesSinceLastUpdate = 0;
                  lastSpeedUpdate.reset();
                } else {
                  _updateTask(task.id, (t) => t.copyWith(processedBytes: processedBytes));
                }
              }
            );
            if (copiedBytes > 0) processedFiles++;
            _updateTask(task.id, (t) => t.copyWith(processedFiles: processedFiles));
          }
        }
        if (isMove && !_isCancelled) {
          await dir.delete(recursive: true);
        }
      } else {
        final copiedBytes = await _copyFileWithProgress(
          source, destPath, task,
          onProgress: (bytes) {
             processedBytes += bytes;
             _updateTask(task.id, (t) => t.copyWith(processedBytes: processedBytes));
          }
        );
        if (copiedBytes > 0) processedFiles++;
        _updateTask(task.id, (t) => t.copyWith(processedFiles: processedFiles));
        
        if (isMove && !_isCancelled) {
          await File(source).delete();
        }
      }
    }
  }

  bool _isSameVolume(String path1, String path2) {
    // Very naive check for Android, assuming different volumes have different roots like /storage/emulated/0 vs /storage/1234-5678
    if (path1.startsWith('/storage/emulated/') && path2.startsWith('/storage/emulated/')) return true;
    final p1Root = path1.split('/').take(3).join('/');
    final p2Root = path2.split('/').take(3).join('/');
    return p1Root == p2Root;
  }

  Future<void> _handleConflictAndMove(String source, String dest, OperationTask task) async {
    String finalDest = dest;
    if (FileSystemEntity.typeSync(finalDest) != FileSystemEntityType.notFound) {
      final res = await _askConflictResolution(task, finalDest);
      if (res == ConflictResolution.skip) return;
      if (res == ConflictResolution.keepBoth) {
        finalDest = _generateUniquePath(finalDest);
      }
    }
    
    final entity = FileSystemEntity.isDirectorySync(source) ? Directory(source) : File(source);
    await entity.rename(finalDest);
  }

  Future<int> _copyFileWithProgress(String source, String dest, OperationTask task, {required void Function(int) onProgress}) async {
    String finalDest = dest;
    
    // Check conflict
    if (File(finalDest).existsSync()) {
      final res = await _askConflictResolution(task, finalDest);
      if (res == ConflictResolution.skip) {
        return 0; // Skip
      } else if (res == ConflictResolution.keepBoth) {
        finalDest = _generateUniquePath(finalDest);
      }
      // If replace, just proceed, it will overwrite
    }

    final sourceFile = File(source);
    final destFile = File(finalDest);
    
    await destFile.parent.create(recursive: true);

    final rafSource = await sourceFile.open(mode: FileMode.read);
    final rafDest = await destFile.open(mode: FileMode.write);
    
    int totalCopied = 0;
    try {
      final bufferSize = 1024 * 64; // 64KB chunk
      while (true) {
        await _checkPauseCancel();
        if (_isCancelled) break;

        final buffer = await rafSource.read(bufferSize);
        if (buffer.isEmpty) break;
        
        await rafDest.writeFrom(buffer);
        totalCopied += buffer.length;
        onProgress(buffer.length);
      }
    } finally {
      await rafSource.close();
      await rafDest.close();
      if (_isCancelled) {
        // cleanup partial file
        if (await destFile.exists()) await destFile.delete();
      }
    }
    return totalCopied;
  }

  Future<ConflictResolution> _askConflictResolution(OperationTask task, String conflictPath) async {
    if (_applyAllConflicts && _defaultConflictResolution != null) {
      return _defaultConflictResolution!;
    }
    
    _updateTask(task.id, (t) => t.copyWith(
      status: OperationStatus.waitingForConflict, 
      conflictFilePath: conflictPath
    ));
    
    _conflictCompleter = Completer<ConflictResolution>();
    final res = await _conflictCompleter!.future;
    
    _updateTask(task.id, (t) => t.copyWith(status: OperationStatus.running, conflictFilePath: null));
    return res;
  }

  String _generateUniquePath(String originalPath) {
    final dir = p.dirname(originalPath);
    final name = p.basenameWithoutExtension(originalPath);
    final ext = p.extension(originalPath);
    
    int counter = 1;
    String newPath = originalPath;
    while (File(newPath).existsSync() || Directory(newPath).existsSync()) {
      newPath = p.join(dir, '${name}_($counter)$ext');
      counter++;
    }
    return newPath;
  }

  Future<void> _checkPauseCancel() async {
    if (_isPaused && _pauseCompleter != null) {
      await _pauseCompleter!.future;
    }
  }
}
