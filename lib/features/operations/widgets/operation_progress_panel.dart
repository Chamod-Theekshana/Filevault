import 'dart:async';

import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/file_operation.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Localised verb for an operation type ("Copying", "Extracting"...).
String operationVerb(AppLocalizations l10n, OperationType type) => switch (type) {
      OperationType.copy => l10n.operationCopy,
      OperationType.move => l10n.operationMove,
      OperationType.trash => l10n.operationTrash,
      OperationType.delete => l10n.operationDelete,
      OperationType.restore => l10n.operationRestore,
      OperationType.compress => l10n.operationCompress,
      OperationType.extract => l10n.operationExtract,
      OperationType.encrypt => l10n.operationEncrypt,
      OperationType.decrypt => l10n.operationDecrypt,
    };

String operationErrorText(AppLocalizations l10n, String? code) => switch (code) {
      'permission' => l10n.errorPermission,
      'notFound' => l10n.errorNotFound,
      'diskFull' => l10n.errorDiskFull,
      'nameTooLong' => l10n.errorNameTooLong,
      'exists' => l10n.errorExists,
      'password' => l10n.wrongPassword,
      'unsupported' => l10n.unsupportedArchive,
      'cancelled' => l10n.errorCancelled,
      'sameFolder' => l10n.errorSameFolder,
      'intoItself' => l10n.errorIntoItself,
      _ => l10n.errorIo,
    };

/// Floating card pinned above the navigation bar while the queue is busy.
class OperationProgressPanel extends ConsumerStatefulWidget {
  const OperationProgressPanel({super.key});

  @override
  ConsumerState<OperationProgressPanel> createState() => _OperationProgressPanelState();
}

class _OperationProgressPanelState extends ConsumerState<OperationProgressPanel> {
  bool _expanded = true;
  Timer? _dismissTimer;
  String? _lastShownFinished;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  /// Auto-hides the "completed" strip a few seconds after an operation ends.
  void _scheduleDismiss(OperationsState state) {
    if (state.active != null || state.finished.isEmpty) return;
    final FileOperation last = state.finished.last;
    if (_lastShownFinished == last.id) return;
    _lastShownFinished = last.id;
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) ref.read(operationsProvider.notifier).dismiss(last.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OperationsState>(operationsProvider, (_, OperationsState next) {
      _scheduleDismiss(next);
    });
    final OperationsState state = ref.watch(operationsProvider);
    final FileOperation? active = state.active;
    final List<FileOperation> queued = state.queued;
    final FileOperation? finished =
        active == null && state.finished.isNotEmpty ? state.finished.last : null;
    final FileOperation? op = active ?? finished;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> anim) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: op == null
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey<String>('${op.id}-${op.status.isFinished}'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: op.status.isFinished
                  ? _FinishedStrip(op: op)
                  : _ActiveCard(
                      op: op,
                      queuedCount: queued.length,
                      expanded: _expanded,
                      onToggle: () => setState(() => _expanded = !_expanded),
                    ),
            ),
    );
  }
}

class _ActiveCard extends ConsumerWidget {
  const _ActiveCard({
    required this.op,
    required this.queuedCount,
    required this.expanded,
    required this.onToggle,
  });

  final FileOperation op;
  final int queuedCount;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OperationsController controller = ref.read(operationsProvider.notifier);
    final bool paused = op.status == OperationStatus.paused;
    final String verb = operationVerb(context.l10n, op.type);
    final String title = op.totalFiles > 0
        ? context.l10n.operationFilesCount(verb, op.totalFiles)
        : verb;
    final Duration? eta = op.estimatedRemaining;
    return FvCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.isDark ? context.colors.primaryContainer : context.colors.primaryFixed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon(op.type), size: 20, color: context.colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  paused ? '${context.l10n.paused} • $title' : title,
                  style: context.texts.headlineSmall?.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (op.totalFiles > 0)
                FvCountBadge(context.l10n.ofFiles(op.processedFiles, op.totalFiles)),
              FvIconButtonPlain(
                icon: expanded ? Icons.expand_less : Icons.expand_more,
                tooltip: expanded ? context.l10n.close : context.l10n.more,
                onPressed: onToggle,
              ),
            ],
          ),
          if (expanded) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(Icons.insert_drive_file_outlined, size: 16, color: context.colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    op.currentFile ?? (op.sources.isEmpty ? '' : p.basename(op.sources.first)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall,
                  ),
                ),
                if (op.destination != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 14, color: context.colors.outline),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      op.destination!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: op.totalBytes == 0 && op.totalFiles == 0 ? null : op.progress,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text(
                  op.totalBytes > 0
                      ? '${op.percent}%  •  ${FileSizeFormatter.format(op.processedBytes)} / ${FileSizeFormatter.format(op.totalBytes)}'
                      : '${op.percent}%',
                  style: context.texts.labelMedium?.copyWith(
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Text(
                  paused
                      ? context.l10n.paused
                      : op.bytesPerSecond > 0
                          ? '${FileSizeFormatter.speed(op.bytesPerSecond)}${eta == null ? '' : '  •  ${context.l10n.timeLeft(FileSizeFormatter.duration(eta))}'}'
                          : context.l10n.calculating,
                  style: context.texts.labelMedium?.copyWith(color: context.colors.primary),
                ),
              ],
            ),
            if (queuedCount > 0) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                '${context.l10n.queued}: $queuedCount',
                style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: FvTonalButton(
                    label: paused ? context.l10n.resume : context.l10n.pause,
                    icon: paused ? Icons.play_arrow : Icons.pause,
                    expand: true,
                    onPressed: _supportsPause(op.type)
                        ? () => paused ? controller.resume(op.id) : controller.pause(op.id)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => controller.cancel(op.id),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colors.errorContainer.withValues(alpha: context.isDark ? 0.5 : 1),
                      foregroundColor: context.isDark ? context.colors.error : context.colors.onErrorContainer,
                      minimumSize: const Size(64, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.close, size: 18),
                        const SizedBox(width: 6),
                        Text(context.l10n.cancel),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static bool _supportsPause(OperationType t) =>
      t == OperationType.copy || t == OperationType.move;

  static IconData _icon(OperationType t) => switch (t) {
        OperationType.copy => Icons.content_copy_outlined,
        OperationType.move => Icons.drive_file_move_outlined,
        OperationType.trash => Icons.delete_outline,
        OperationType.delete => Icons.delete_forever_outlined,
        OperationType.restore => Icons.restore_from_trash_outlined,
        OperationType.compress => Icons.folder_zip_outlined,
        OperationType.extract => Icons.unarchive_outlined,
        OperationType.encrypt => Icons.lock_outline,
        OperationType.decrypt => Icons.lock_open_outlined,
      };
}

class _FinishedStrip extends ConsumerWidget {
  const _FinishedStrip({required this.op});

  final FileOperation op;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool ok = op.status == OperationStatus.completed;
    final bool cancelled = op.status == OperationStatus.cancelled;
    final String verb = operationVerb(context.l10n, op.type);
    final String text = ok
        ? '$verb • ${context.l10n.completed}'
        : cancelled
            ? '$verb • ${context.l10n.cancelled}'
            : '${context.l10n.operationFailedTitle}: ${operationErrorText(context.l10n, op.errorMessage)}';
    return FvCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle : cancelled ? Icons.remove_circle_outline : Icons.error_outline,
            color: ok ? context.tokens.success : cancelled ? context.colors.outline : context.colors.error,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: context.texts.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
          FvIconButtonPlain(
            icon: Icons.close,
            tooltip: context.l10n.close,
            onPressed: () => ref.read(operationsProvider.notifier).dismiss(op.id),
          ),
        ],
      ),
    );
  }
}
