import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/file_utils.dart';
import '../models/operation_task.dart';
import '../services/operation_queue_service.dart';
import 'conflict_dialog.dart';

class OperationProgressPanel extends ConsumerWidget {
  const OperationProgressPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(operationQueueProvider);
    final activeTask = state.currentActiveTask;
    final notifier = ref.read(operationQueueProvider.notifier);

    if (activeTask == null) return const SizedBox.shrink();

    // If waiting for conflict, we might want to show the dialog
    if (activeTask.status == OperationStatus.waitingForConflict && activeTask.conflictFilePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Prevent showing multiple times if rebuilt
        if (ModalRoute.of(context)?.isCurrent == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => ConflictDialog(
              conflictFilePath: activeTask.conflictFilePath!,
              onResolve: (resolution, applyAll) {
                notifier.resolveConflict(resolution, applyAll);
              },
            ),
          );
        }
      });
    }

    if (state.isMinimized) {
      return Positioned(
        bottom: 80 + 16, // Above bottom nav
        right: 16,
        child: FloatingActionButton.extended(
          onPressed: notifier.toggleMinimize,
          icon: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: Text('${(activeTask.progress * 100).toInt()}%'),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isPaused = activeTask.status == OperationStatus.paused;
    final typeName = activeTask.type.name[0].toUpperCase() + activeTask.type.name.substring(1);
    final actionName = isPaused ? 'Paused' : '${typeName}ing';

    return Positioned(
      bottom: 80 + 16,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_getIconForType(activeTask.type), size: 20, color: colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$actionName ${activeTask.totalFiles} items',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${activeTask.processedFiles} of ${activeTask.totalFiles}',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: notifier.toggleMinimize,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Current File indicator
              if (activeTask.destinationPath != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'To: ${p.basename(activeTask.destinationPath!)}',
                          style: textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
              const SizedBox(height: 12),
              
              // Progress Bar
              LinearProgressIndicator(
                value: activeTask.progress,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(activeTask.progress * 100).toInt()}% • ${FileUtils.formatBytes(activeTask.processedBytes, 1)} / ${FileUtils.formatBytes(activeTask.totalBytes, 1)}',
                    style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${FileUtils.formatBytes(activeTask.currentSpeedBytesPerSecond.toInt(), 1)}/s',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: isPaused ? notifier.resumeCurrent : notifier.pauseCurrent,
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(isPaused ? 'Resume' : 'Pause'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                      ),
                      onPressed: notifier.cancelCurrent,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getIconForType(OperationType type) {
    switch (type) {
      case OperationType.copy: return Icons.content_copy;
      case OperationType.move: return Icons.drive_file_move;
      case OperationType.delete: return Icons.delete;
      case OperationType.rename: return Icons.drive_file_rename_outline;
      case OperationType.extract: return Icons.unarchive;
      case OperationType.compress: return Icons.archive;
      default: return Icons.work;
    }
  }
}
