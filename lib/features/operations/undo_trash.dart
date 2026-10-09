import 'package:filevault/core/di/providers.dart';
import 'package:filevault/domain/models/file_operation.dart';
import 'package:filevault/domain/models/trash_item.dart';
import 'package:filevault/domain/repositories/trash_repository.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Moves [paths] to the trash. The progress panel then offers "Undo" once
/// the move has finished – undo instead of a confirmation dialog for an
/// action that is fully reversible.
void trashWithUndo(BuildContext context, WidgetRef ref, List<String> paths) {
  if (paths.isEmpty) return;
  ref.read(operationsProvider.notifier).enqueueTrash(paths);
}

/// Restores everything a finished "move to trash" operation put in the bin.
///
/// Everything needed is read from [ref] before the first `await`, so this
/// keeps working even if the calling widget goes away meanwhile.
Future<int> undoTrash(WidgetRef ref, FileOperation op) async {
  if (op.type != OperationType.trash) return 0;
  final TrashRepository trash = ref.read(trashRepositoryProvider);
  final OperationsController ops = ref.read(operationsProvider.notifier);
  final Set<String> paths = op.sources.toSet();
  final DateTime since = op.createdAt.subtract(const Duration(seconds: 2));
  final List<TrashItem> all = await trash.items();
  final List<TrashItem> mine = all
      .where((TrashItem t) => paths.contains(t.originalPath) && !t.deletedAt.isBefore(since))
      .toList(growable: false);
  if (mine.isNotEmpty) ops.enqueueRestore(mine);
  return mine.length;
}
