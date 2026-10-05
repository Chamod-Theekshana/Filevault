import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/folder_picker_sheet.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/core/widgets/fv_thumbnail.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:filevault/features/archive/widgets/create_archive_sheet.dart';
import 'package:filevault/features/browser/widgets/properties_dialog.dart';
import 'package:filevault/features/browser/widgets/tag_picker_sheet.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:filevault/features/viewer/open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Result of the per-file action sheet so the caller can refresh.
enum FileActionResult { none, changed }

/// Contextual actions for a single file or folder (the "⋮" menu).
Future<FileActionResult> showFileActionsSheet(
  BuildContext context,
  WidgetRef ref,
  FileEntry entry, {
  List<FileEntry> siblings = const <FileEntry>[],
  bool Function(String name)? nameExists,
}) async {
  final FileActionResult? result = await showModalBottomSheet<FileActionResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _FileActionsSheet(
      entry: entry,
      siblings: siblings,
      nameExists: nameExists,
    ),
  );
  return result ?? FileActionResult.none;
}

class _FileActionsSheet extends ConsumerStatefulWidget {
  const _FileActionsSheet({
    required this.entry,
    required this.siblings,
    required this.nameExists,
  });

  final FileEntry entry;
  final List<FileEntry> siblings;
  final bool Function(String name)? nameExists;

  @override
  ConsumerState<_FileActionsSheet> createState() => _FileActionsSheetState();
}

class _FileActionsSheetState extends ConsumerState<_FileActionsSheet> {
  bool _favorite = false;
  bool _loadedFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final bool fav = await ref.read(collectionsRepositoryProvider).isFavorite(widget.entry.path);
    if (mounted) {
      setState(() {
        _favorite = fav;
        _loadedFavorite = true;
      });
    }
  }

  void _close([FileActionResult result = FileActionResult.none]) {
    if (mounted) Navigator.of(context).pop(result);
  }

  FileEntry get entry => widget.entry;

  Future<void> _rename() async {
    final String? name = await showTextInputDialog(
      context,
      title: context.l10n.renameTitle,
      hint: context.l10n.fileNameHint,
      initialValue: entry.name,
      exists: (String n) => n != entry.name && (widget.nameExists?.call(n) ?? false),
    );
    if (name == null || name == entry.name) return;
    final Result<FileEntry> r =
        await ref.read(fileRepositoryProvider).rename(entry.path, name);
    final FileEntry? renamed = r.valueOrNull;
    if (renamed != null) {
      await ref.read(collectionsRepositoryProvider).pathMoved(entry.path, renamed.path);
      await ref.read(indexRepositoryProvider).movePath(entry.path, renamed.path);
    }
    if (!mounted) return;
    if (renamed == null) {
      context.showSnack(context.l10n.somethingWentWrong);
      _close();
    } else {
      context.showSnack(context.l10n.renamed);
      _close(FileActionResult.changed);
    }
  }

  Future<void> _copyOrMove({required bool move}) async {
    final String? destination = await showFolderPicker(
      context,
      confirmLabel: move ? context.l10n.moveHere : context.l10n.copyHere,
      initialPath: entry.parentPath,
      disabledPaths: entry.isDirectory ? <String>{entry.path} : <String>{},
    );
    if (destination == null || !mounted) return;
    final OperationsController ops = ref.read(operationsProvider.notifier);
    if (move) {
      ops.enqueueMove(<String>[entry.path], destination);
    } else {
      ops.enqueueCopy(<String>[entry.path], destination);
    }
    _close(FileActionResult.changed);
  }

  Future<void> _delete() async {
    final bool confirm = ref.read(settingsProvider).confirmBeforeDelete;
    if (confirm) {
      final bool ok = await showConfirmDialog(
        context,
        title: context.l10n.deleteTitle,
        message: context.l10n.deleteBody(1),
        confirmLabel: context.l10n.moveToTrash,
        destructive: true,
        icon: Icons.delete_outline,
      );
      if (!ok || !mounted) return;
    }
    ref.read(operationsProvider.notifier).enqueueTrash(<String>[entry.path]);
    _close(FileActionResult.changed);
  }

  Future<void> _compress() async {
    final CreateArchiveRequest? request = await showCreateArchiveSheet(
      context,
      sources: <FileEntry>[entry],
      suggestedName: entry.stem,
      destinationDir: entry.parentPath,
    );
    if (request == null || !mounted) return;
    ref.read(operationsProvider.notifier).enqueueCompress(
          request.sources,
          request.archivePath,
          format: request.format,
          level: request.level,
          password: request.password,
          deleteSources: request.deleteSources,
        );
    _close(FileActionResult.changed);
  }

  Future<void> _extract() async {
    final String? destination = await showFolderPicker(
      context,
      confirmLabel: context.l10n.extractHere,
      initialPath: entry.parentPath,
      title: context.l10n.extractTo,
    );
    if (destination == null || !mounted) return;
    ref.read(operationsProvider.notifier).enqueueExtract(entry.path, destination);
    _close(FileActionResult.changed);
  }

  Future<void> _toggleFavorite() async {
    if (_favorite) {
      await ref.read(collectionsRepositoryProvider).removeFavorite(entry.path);
    } else {
      await ref.read(collectionsRepositoryProvider).addFavorite(entry);
    }
    if (!mounted) return;
    context.showSnack(_favorite ? context.l10n.removedFromFavorites : context.l10n.addedToFavorites);
    _close(FileActionResult.changed);
  }

  Future<void> _addToVault() async {
    final bool configured = await ref.read(vaultRepositoryProvider).isConfigured();
    if (!mounted) return;
    _close();
    if (!configured) {
      context.push(AppRoutes.vaultSetup);
      return;
    }
    if (!ref.read(vaultRepositoryProvider).isUnlocked) {
      context.push(AppRoutes.vault, extra: <String, Object?>{'pendingAdd': <String>[entry.path]});
      return;
    }
    ref.read(operationsProvider.notifier).enqueueEncrypt(<String>[entry.path]);
  }

  @override
  Widget build(BuildContext context) {
    final bool canExtract =
        entry.isArchive && ref.read(archiveRepositoryProvider).canOpen(entry.path);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: <Widget>[
                  FvThumbnail(entry: entry, size: 52, radius: 14),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.name,
                          style: context.texts.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.isDirectory
                              ? '${context.l10n.folder} • ${DateFormatter.short(entry.modified)}'
                              : '${FileSizeFormatter.format(entry.size)} • ${DateFormatter.full(entry.modified)}',
                          style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.tokens.cardBorder),
            if (!entry.isDirectory)
              FvSheetAction(
                icon: Icons.open_in_new,
                label: context.l10n.openWith,
                onTap: () {
                  // Capture the page behind the sheet before popping, so the
                  // follow-up uses a context that is still mounted.
                  final BuildContext host = Navigator.of(context).context;
                  _close();
                  openWithExternalApp(host, entry);
                },
              ),
            if (!entry.isDirectory)
              FvSheetAction(
                icon: Icons.share_outlined,
                label: context.l10n.share,
                onTap: () async {
                  _close();
                  await SharePlus.instance.share(
                    ShareParams(files: <XFile>[XFile(entry.path)]),
                  );
                },
              ),
            Divider(height: 1, color: context.tokens.cardBorder),
            FvSheetAction(
              icon: Icons.content_copy_outlined,
              label: context.l10n.copy,
              onTap: () => _copyOrMove(move: false),
            ),
            FvSheetAction(
              icon: Icons.drive_file_move_outlined,
              label: context.l10n.move,
              onTap: () => _copyOrMove(move: true),
            ),
            FvSheetAction(
              icon: Icons.drive_file_rename_outline,
              label: context.l10n.rename,
              onTap: _rename,
            ),
            FvSheetAction(
              icon: Icons.copy_all_outlined,
              label: context.l10n.duplicate,
              onTap: () async {
                final Result<FileEntry> r =
                    await ref.read(fileRepositoryProvider).duplicate(entry.path);
                if (!mounted) return;
                if (r.isFailure) context.showSnack(context.l10n.somethingWentWrong);
                _close(FileActionResult.changed);
              },
            ),
            if (canExtract)
              FvSheetAction(
                icon: Icons.unarchive_outlined,
                label: context.l10n.extract,
                onTap: _extract,
              ),
            FvSheetAction(
              icon: Icons.folder_zip_outlined,
              label: context.l10n.compressToZip,
              onTap: _compress,
            ),
            if (!entry.isDirectory)
              FvSheetAction(
                icon: Icons.lock_outline,
                label: context.l10n.addToSecureFolder,
                onTap: _addToVault,
              ),
            Divider(height: 1, color: context.tokens.cardBorder),
            FvSheetAction(
              icon: _favorite ? Icons.star : Icons.star_outline,
              label: _favorite ? context.l10n.removeFromFavorites : context.l10n.addToFavorites,
              enabled: _loadedFavorite,
              onTap: _toggleFavorite,
            ),
            FvSheetAction(
              icon: Icons.label_outline,
              label: context.l10n.addTags,
              onTap: () async {
                await showTagPicker(context, ref, entry.path);
                if (mounted) _close(FileActionResult.changed);
              },
            ),
            FvSheetAction(
              icon: Icons.link,
              label: context.l10n.copyPath,
              onTap: () {
                Clipboard.setData(ClipboardData(text: entry.path));
                context.showSnack(context.l10n.copied);
                _close();
              },
            ),
            FvSheetAction(
              icon: Icons.info_outline,
              label: context.l10n.properties,
              onTap: () {
                final BuildContext host = Navigator.of(context).context;
                _close();
                showPropertiesDialog(host, entry);
              },
            ),
            Divider(height: 1, color: context.tokens.cardBorder),
            FvSheetAction(
              icon: Icons.delete_outline,
              label: context.l10n.moveToTrash,
              destructive: true,
              onTap: _delete,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Bottom action bar shown while items are selected.
class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({
    super.key,
    required this.onCopy,
    required this.onMove,
    required this.onDelete,
    required this.onShare,
    required this.onMore,
    this.shareEnabled = true,
  });

  final VoidCallback onCopy;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final bool shareEnabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.isDark ? context.colors.surfaceContainerHigh : context.colors.surfaceContainerLowest,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.tokens.cardBorder)),
        ),
        padding: EdgeInsets.only(bottom: context.padding.bottom, top: 6),
        child: Row(
          children: <Widget>[
            _Action(icon: Icons.content_copy_outlined, label: context.l10n.copy, onTap: onCopy),
            _Action(icon: Icons.drive_file_move_outlined, label: context.l10n.move, onTap: onMove),
            _Action(
              icon: Icons.delete_outline,
              label: context.l10n.delete,
              onTap: onDelete,
              destructive: true,
            ),
            _Action(
              icon: Icons.share_outlined,
              label: context.l10n.share,
              onTap: shareEnabled ? onShare : null,
            ),
            _Action(icon: Icons.more_horiz, label: context.l10n.more, onTap: onMore),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color color = onTap == null
        ? context.colors.outline
        : destructive
            ? context.colors.error
            : context.colors.onSurface;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: context.texts.labelMedium?.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "More" sheet for a multi-selection.
Future<String?> showSelectionMoreSheet(BuildContext context, {required bool canCompress}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (BuildContext context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (canCompress)
            FvSheetAction(
              icon: Icons.folder_zip_outlined,
              label: context.l10n.compressToZip,
              onTap: () => Navigator.of(context).pop('compress'),
            ),
          FvSheetAction(
            icon: Icons.lock_outline,
            label: context.l10n.addToSecureFolder,
            onTap: () => Navigator.of(context).pop('vault'),
          ),
          FvSheetAction(
            icon: Icons.star_outline,
            label: context.l10n.addToFavorites,
            onTap: () => Navigator.of(context).pop('favorite'),
          ),
          FvSheetAction(
            icon: Icons.select_all,
            label: context.l10n.selectAll,
            onTap: () => Navigator.of(context).pop('selectAll'),
          ),
          FvSheetAction(
            icon: Icons.flip_to_back,
            label: context.l10n.invertSelection,
            onTap: () => Navigator.of(context).pop('invert'),
          ),
          FvSheetAction(
            icon: Icons.delete_forever_outlined,
            label: context.l10n.deletePermanently,
            destructive: true,
            onTap: () => Navigator.of(context).pop('deleteForever'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Sort options sheet shared by the browser and category screens.
Future<void> showSortSheet(
  BuildContext context, {
  required SortSpec sort,
  required ValueChanged<SortSpec> onChanged,
  bool? showHidden,
  VoidCallback? onToggleHidden,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) => _SortSheet(
      sort: sort,
      onChanged: onChanged,
      showHidden: showHidden,
      onToggleHidden: onToggleHidden,
    ),
  );
}

class _SortSheet extends StatefulWidget {
  const _SortSheet({
    required this.sort,
    required this.onChanged,
    required this.showHidden,
    required this.onToggleHidden,
  });

  final SortSpec sort;
  final ValueChanged<SortSpec> onChanged;
  final bool? showHidden;
  final VoidCallback? onToggleHidden;

  @override
  State<_SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<_SortSheet> {
  late SortSpec _sort = widget.sort;

  void _update(SortSpec next) {
    setState(() => _sort = next);
    widget.onChanged(next);
  }

  String _label(SortField f) => switch (f) {
        SortField.name => context.l10n.name,
        SortField.size => context.l10n.size,
        SortField.date => context.l10n.date,
        SortField.type => context.l10n.type,
      };

  IconData _icon(SortField f) => switch (f) {
        SortField.name => Icons.sort_by_alpha,
        SortField.size => Icons.data_usage,
        SortField.date => Icons.schedule,
        SortField.type => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final bool? hidden = widget.showHidden;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(context.l10n.sortBy, style: context.texts.headlineSmall),
            ),
          ),
          for (final SortField f in SortField.values)
            ListTile(
              leading: Icon(_icon(f)),
              title: Text(_label(f)),
              trailing: _sort.field != f
                  ? null
                  : Icon(
                      _sort.direction == SortDirection.asc
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: context.colors.primary,
                    ),
              selected: _sort.field == f,
              onTap: () => _update(
                _sort.field == f
                    ? _sort.copyWith(
                        direction: _sort.direction == SortDirection.asc
                            ? SortDirection.desc
                            : SortDirection.asc,
                      )
                    : _sort.copyWith(field: f, direction: SortDirection.asc),
              ),
            ),
          Divider(height: 1, color: context.tokens.cardBorder),
          SwitchListTile(
            value: _sort.foldersFirst,
            onChanged: (bool v) => _update(_sort.copyWith(foldersFirst: v)),
            title: Text(context.l10n.foldersFirst),
            secondary: const Icon(Icons.folder_outlined),
          ),
          if (hidden != null && widget.onToggleHidden != null)
            SwitchListTile(
              value: hidden,
              onChanged: (_) {
                widget.onToggleHidden!();
                Navigator.of(context).pop();
              },
              title: Text(context.l10n.showHiddenFiles),
              subtitle: Text(context.l10n.showHiddenSub),
              secondary: const Icon(Icons.visibility_outlined),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
