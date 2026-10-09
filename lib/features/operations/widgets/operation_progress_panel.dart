import 'dart:async';

import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/file_operation.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/operations/undo_trash.dart';
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
      'vaultLocked' => l10n.errorVaultLocked,
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
    final Duration visible = last.type == OperationType.trash &&
            last.status == OperationStatus.completed
        ? const Duration(seconds: 8)
        : const Duration(seconds: 5);
    _dismissTimer = Timer(visible, () {
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
    final bool measuring = op.totalBytes == 0 && op.totalFiles == 0;
    final TextStyle? numeric = context.texts.labelMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final String speedText = paused
        ? context.l10n.paused
        : op.bytesPerSecond > 0
            ? FileSizeFormatter.speed(op.bytesPerSecond) +
                (eta == null ? '' : '  ·  ${context.l10n.timeLeft(FileSizeFormatter.duration(eta))}')
            : context.l10n.calculating;

    if (!expanded) {
      // Collapsed: one slim line that still shows the essentials.
      return FvCard(
        elevated: true,
        onTap: onToggle,
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                value: measuring ? null : op.progress,
                strokeWidth: 3,
                backgroundColor: context.tokens.chipFill,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$title · ${op.percent}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleSmall,
              ),
            ),
            Text(speedText, style: numeric),
            FvIconButtonPlain(icon: Icons.expand_less, tooltip: context.l10n.more, onPressed: onToggle),
          ],
        ),
      );
    }

    return FvCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
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
                  color: context.tokens.tonal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon(op.type), size: 20, color: context.tokens.onTonal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: context.texts.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      op.currentFile ?? (op.sources.isEmpty ? '' : p.basename(op.sources.first)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                measuring ? '' : '${op.percent}%',
                style: context.texts.headlineSmall?.copyWith(
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              FvIconButtonPlain(icon: Icons.expand_more, tooltip: context.l10n.hide, onPressed: onToggle),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: measuring ? null : op.progress,
                minHeight: 6,
                backgroundColor: context.tokens.chipFill,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    <String>[
                      if (op.totalBytes > 0)
                        '${FileSizeFormatter.format(op.processedBytes)} / ${FileSizeFormatter.format(op.totalBytes)}',
                      if (op.totalFiles > 0) context.l10n.filesProgress(op.processedFiles, op.totalFiles),
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: numeric,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  speedText,
                  style: context.texts.labelMedium?.copyWith(
                    color: context.colors.primary,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (op.destination != null && op.type != OperationType.compress) ...<Widget>[
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Icon(Icons.subdirectory_arrow_right, size: 14, color: context.colors.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    op.destination!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
          if (queuedCount > 0) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              context.l10n.queuedCount(queuedCount),
              style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (_supportsPause(op.type))
                TextButton.icon(
                  onPressed: () => paused ? controller.resume(op.id) : controller.pause(op.id),
                  icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18),
                  label: Text(paused ? context.l10n.resume : context.l10n.pause),
                ),
              TextButton.icon(
                onPressed: () => controller.cancel(op.id),
                style: TextButton.styleFrom(
                  foregroundColor: context.isDark ? Colors.white : context.colors.error,
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(context.l10n.cancel),
              ),
            ],
          ),
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
    final bool canUndo = ok && op.type == OperationType.trash;
    final String text = ok
        ? _doneText(context, op)
        : cancelled
            ? '${operationVerb(context.l10n, op.type)} · ${context.l10n.cancelled}'
            : '${context.l10n.operationFailedTitle}: ${operationErrorText(context.l10n, op.errorMessage)}';
    return FvCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
      child: Row(
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle_rounded : cancelled ? Icons.remove_circle_outline : Icons.error_outline,
            color: ok ? context.tokens.success : cancelled ? context.colors.outline : context.colors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: context.texts.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          if (canUndo)
            TextButton(
              onPressed: () {
                // undoTrash reads what it needs synchronously, so dismissing
                // the strip right after is safe.
                undoTrash(ref, op);
                ref.read(operationsProvider.notifier).dismiss(op.id);
              },
              child: Text(context.l10n.undo),
            ),
          FvIconButtonPlain(
            icon: Icons.close,
            tooltip: context.l10n.close,
            onPressed: () => ref.read(operationsProvider.notifier).dismiss(op.id),
          ),
        ],
      ),
    );
  }

  static String _doneText(BuildContext context, FileOperation op) {
    final int n = op.totalFiles > 0 ? op.totalFiles : op.sources.length;
    return switch (op.type) {
      OperationType.copy => context.l10n.doneCopied(n),
      OperationType.move => context.l10n.doneMoved(n),
      OperationType.trash => context.l10n.movedToTrash(op.sources.length),
      OperationType.delete => context.l10n.doneDeleted(op.sources.length),
      OperationType.restore => context.l10n.doneRestored(n),
      OperationType.encrypt => context.l10n.vaultAdded(n),
      OperationType.decrypt => context.l10n.vaultExported(n),
      OperationType.compress => context.l10n.archiveCreated,
      OperationType.extract => context.l10n.extractionComplete,
    };
  }
}
