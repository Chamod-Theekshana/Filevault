import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/models/file_item.dart';

part 'operation_task.freezed.dart';

enum OperationType { copy, move, delete, rename, create, extract, compress }
enum OperationStatus { queued, running, paused, completed, error, cancelled, waitingForConflict }

@freezed
abstract class OperationTask with _$OperationTask {
  const factory OperationTask({
    required String id,
    required OperationType type,
    required List<String> sourcePaths,
    String? destinationPath,
    @Default(OperationStatus.queued) OperationStatus status,
    
    // Progress metrics
    @Default(0) int totalFiles,
    @Default(0) int processedFiles,
    @Default(0) int totalBytes,
    @Default(0) int processedBytes,
    @Default(0) double currentSpeedBytesPerSecond,
    
    // Conflict handling
    String? conflictFilePath,
    
    String? errorMessage,
  }) = _OperationTask;
  
  const OperationTask._();
  
  double get progress => totalBytes > 0 ? processedBytes / totalBytes : (totalFiles > 0 ? processedFiles / totalFiles : 0.0);
}
