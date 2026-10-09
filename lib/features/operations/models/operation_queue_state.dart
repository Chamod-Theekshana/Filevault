import 'package:freezed_annotation/freezed_annotation.dart';
import 'operation_task.dart';

part 'operation_queue_state.freezed.dart';

@freezed
abstract class OperationQueueState with _$OperationQueueState {
  const factory OperationQueueState({
    @Default([]) List<OperationTask> tasks,
    @Default(false) bool isMinimized, // For the bottom sheet UI
  }) = _OperationQueueState;
  
  const OperationQueueState._();
  
  OperationTask? get currentActiveTask => 
      tasks.where((t) => t.status == OperationStatus.running || 
                         t.status == OperationStatus.paused || 
                         t.status == OperationStatus.waitingForConflict).firstOrNull;
}
