import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/file_operation.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/operations/widgets/operation_progress_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final AutoDisposeFutureProvider<List<OperationRecord>> operationHistoryProvider =
    FutureProvider.autoDispose<List<OperationRecord>>((Ref ref) {
  ref.watch(operationFinishedProvider);
  return ref.watch(collectionsRepositoryProvider).operationHistory();
});

/// Queue + history of file operations.
class OperationsView extends ConsumerWidget {
  const OperationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OperationsState live = ref.watch(operationsProvider);
    final AsyncValue<List<OperationRecord>> history = ref.watch(operationHistoryProvider);
    final List<FileOperation> activeOps =
        live.operations.where((FileOperation o) => o.status.isActive).toList();
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: context.l10n.operationsHistory,
        actions: <Widget>[
          FvIconButton(
            icon: Icons.delete_sweep_outlined,
            tooltip: context.l10n.clearHistory,
            onPressed: () async {
              await ref.read(collectionsRepositoryProvider).clearOperationHistory();
              ref.read(operationsProvider.notifier).clearFinished();
              ref.invalidate(operationHistoryProvider);
            },
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text(context.l10n.somethingWentWrong)),
        data: (List<OperationRecord> records) {
          if (activeOps.isEmpty && records.isEmpty) {
            return FvEmptyState(
              icon: Icons.sync_alt,
              title: context.l10n.noOperations,
              message: context.l10n.noOperationsBody,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: <Widget>[
              if (activeOps.isNotEmpty) ...<Widget>[
                FvSectionHeader(title: context.l10n.running, count: activeOps.length, padding: const EdgeInsets.fromLTRB(0, 8, 0, 8)),
                FvCard(
                  child: Column(
                    children: <Widget>[
                      for (final FileOperation op in activeOps) _LiveRow(op: op),
                    ],
                  ),
                ),
              ],
              if (records.isNotEmpty) ...<Widget>[
                FvSectionHeader(title: context.l10n.completed, count: records.length, padding: const EdgeInsets.fromLTRB(0, 20, 0, 8)),
                FvCard(
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < records.length; i++)
                        _HistoryRow(record: records[i], last: i == records.length - 1),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LiveRow extends ConsumerWidget {
  const _LiveRow({required this.op});

  final FileOperation op;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OperationsController c = ref.read(operationsProvider.notifier);
    final bool paused = op.status == OperationStatus.paused;
    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CircularProgressIndicator(value: op.status == OperationStatus.queued ? 0 : op.progress, strokeWidth: 4),
            Text('${op.percent}', style: context.texts.labelSmall),
          ],
        ),
      ),
      title: Text(
        context.l10n.operationFilesCount(operationVerb(context.l10n, op.type), op.totalFiles),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        op.status == OperationStatus.queued
            ? context.l10n.queued
            : paused
                ? context.l10n.paused
                : op.currentFile ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (op.status != OperationStatus.queued &&
              (op.type == OperationType.copy || op.type == OperationType.move))
            IconButton(
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
              onPressed: () => paused ? c.resume(op.id) : c.pause(op.id),
            ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => c.cancel(op.id)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record, required this.last});

  final OperationRecord record;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final bool ok = record.status == OperationStatus.completed;
    final Color color = ok
        ? context.tokens.success
        : record.status == OperationStatus.cancelled
            ? context.colors.outline
            : context.colors.error;
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      child: ListTile(
        leading: Icon(
          ok ? Icons.check_circle_outline : Icons.error_outline,
          color: color,
        ),
        title: Text(
          '${operationVerb(context.l10n, record.type)} • ${context.l10n.fileCount(record.fileCount)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          <String>[
            p.basename(record.source),
            if (record.destination != null) '→ ${record.destination}',
            if (record.totalBytes > 0) FileSizeFormatter.format(record.totalBytes),
            if (!ok) operationErrorText(context.l10n, record.errorMessage),
          ].join('  •  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          DateFormatter.ago(record.finishedAt ?? record.createdAt),
          style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
