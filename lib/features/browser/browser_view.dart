import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/folder_picker_sheet.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/core/widgets/fv_file_tile.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:filevault/features/archive/widgets/create_archive_sheet.dart';
import 'package:filevault/features/browser/browser_viewmodel.dart';
import 'package:filevault/features/browser/widgets/breadcrumb_bar.dart';
import 'package:filevault/features/browser/widgets/file_actions_sheet.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:filevault/features/viewer/open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Folder browser: breadcrumbs, folder/file sections, selection mode,
/// list/grid toggle and the create FAB.
class BrowserView extends ConsumerStatefulWidget {
  const BrowserView({super.key, required this.path});

  final String path;

  @override
  ConsumerState<BrowserView> createState() => _BrowserViewState();
}

class _BrowserViewState extends ConsumerState<BrowserView> {
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  BrowserViewModel get _vm => ref.read(browserProvider(widget.path).notifier);

  /// System back: clear selection, close search, then walk up one folder.
  void _handleBack(BrowserState state) {
    if (state.selecting) {
      _vm.clearSelection();
      return;
    }
    if (_searching) {
      setState(() => _searching = false);
      _searchController.clear();
      _vm.setQuery('');
      return;
    }
    _goBack(state);
  }

  bool _canPopDirectly(BrowserState state) {
    if (state.selecting || _searching) return false;
    // Inside a subfolder, back should go up instead of leaving the browser.
    return _atVolumeRoot(state);
  }

  /// True at the top of a storage volume. The volume is only known after the
  /// first async load, so the primary storage root is the fallback.
  static bool _atVolumeRoot(BrowserState state) {
    final StorageVolume? volume = state.volume;
    if (volume != null) return volume.path == state.path;
    return state.path == AppConstants.primaryStoragePath || state.path == '/';
  }

  /// Back goes up one folder; at a volume root it pops the route when there
  /// is one (the Browse tab root has nothing to pop).
  void _goBack(BrowserState state) {
    final NavigatorState navigator = Navigator.of(context);
    final bool atVolumeRoot = _atVolumeRoot(state);
    if (!atVolumeRoot) {
      final String parent = p.dirname(state.path);
      if (parent != state.path) {
        context.pushReplacement(AppRoutes.withPath(AppRoutes.browse, parent));
        return;
      }
    }
    if (navigator.canPop()) navigator.pop();
  }

  void _open(FileEntry entry, BrowserState state) {
    if (state.selecting) {
      _vm.toggle(entry.path);
      return;
    }
    openFileEntry(context, ref, entry, siblings: state.visible);
  }

  Future<void> _showActions(FileEntry entry, BrowserState state) async {
    final FileActionResult result = await showFileActionsSheet(
      context,
      ref,
      entry,
      siblings: state.visible,
      nameExists: _vm.nameExists,
    );
    if (result == FileActionResult.changed) await _vm.refresh();
  }

  // --------------------------------------------------------- selection ops

  Future<void> _selectionCopyOrMove(BrowserState state, {required bool move}) async {
    final List<String> sources = state.selected.toList();
    final String? destination = await showFolderPicker(
      context,
      confirmLabel: move ? context.l10n.moveHere : context.l10n.copyHere,
      initialPath: state.path,
      disabledPaths: state.selectedEntries
          .where((FileEntry e) => e.isDirectory)
          .map((FileEntry e) => e.path)
          .toSet(),
    );
    if (destination == null || !mounted) return;
    final OperationsController ops = ref.read(operationsProvider.notifier);
    if (move) {
      ops.enqueueMove(sources, destination);
    } else {
      ops.enqueueCopy(sources, destination);
    }
    _vm.clearSelection();
  }

  Future<void> _selectionDelete(BrowserState state, {bool permanent = false}) async {
    final List<String> sources = state.selected.toList();
    final bool confirm = permanent || ref.read(settingsProvider).confirmBeforeDelete;
    if (confirm) {
      final bool ok = await showConfirmDialog(
        context,
        title: permanent ? context.l10n.deletePermanentlyTitle : context.l10n.deleteTitle,
        message: permanent
            ? context.l10n.deletePermanentlyBody(sources.length)
            : context.l10n.deleteBody(sources.length),
        confirmLabel: permanent ? context.l10n.deletePermanently : context.l10n.moveToTrash,
        destructive: true,
        icon: Icons.delete_outline,
      );
      if (!ok || !mounted) return;
    }
    final OperationsController ops = ref.read(operationsProvider.notifier);
    if (permanent) {
      ops.enqueueDelete(sources);
    } else {
      ops.enqueueTrash(sources);
    }
    _vm.clearSelection();
  }

  Future<void> _selectionShare(BrowserState state) async {
    final List<XFile> files = state.selectedEntries
        .where((FileEntry e) => !e.isDirectory)
        .map((FileEntry e) => XFile(e.path))
        .toList();
    if (files.isEmpty) return;
    await SharePlus.instance.share(ShareParams(files: files));
  }

  Future<void> _selectionMore(BrowserState state) async {
    final String? action = await showSelectionMoreSheet(context, canCompress: true);
    if (action == null || !mounted) return;
    switch (action) {
      case 'compress':
        final CreateArchiveRequest? request = await showCreateArchiveSheet(
          context,
          sources: state.selectedEntries,
          suggestedName: _vm.suggestedArchiveName(),
          destinationDir: state.path,
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
        _vm.clearSelection();
      case 'vault':
        final List<String> files = state.selectedEntries
            .where((FileEntry e) => !e.isDirectory)
            .map((FileEntry e) => e.path)
            .toList();
        if (files.isEmpty) {
          context.showSnack(context.l10n.vaultPickFiles);
          return;
        }
        final bool configured = await ref.read(vaultRepositoryProvider).isConfigured();
        if (!mounted) return;
        if (!configured) {
          context.push(AppRoutes.vaultSetup);
          return;
        }
        if (!ref.read(vaultRepositoryProvider).isUnlocked) {
          context.push(AppRoutes.vault, extra: <String, Object?>{'pendingAdd': files});
          _vm.clearSelection();
          return;
        }
        ref.read(operationsProvider.notifier).enqueueEncrypt(files);
        _vm.clearSelection();
      case 'favorite':
        for (final FileEntry e in state.selectedEntries) {
          if (!mounted) return;
          await ref.read(collectionsRepositoryProvider).addFavorite(e);
        }
        if (!mounted) return;
        context.showSnack(context.l10n.addedToFavorites);
        _vm.clearSelection();
      case 'selectAll':
        _vm.selectAll();
      case 'invert':
        _vm.invertSelection();
      case 'deleteForever':
        await _selectionDelete(state, permanent: true);
    }
  }

  Future<void> _create(BrowserState state) async {
    final String? kind = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FvSheetAction(
              icon: Icons.create_new_folder_outlined,
              label: context.l10n.newFolder,
              onTap: () => Navigator.of(context).pop('folder'),
            ),
            FvSheetAction(
              icon: Icons.note_add_outlined,
              label: context.l10n.newFile,
              onTap: () => Navigator.of(context).pop('file'),
            ),
            FvSheetAction(
              icon: Icons.folder_zip_outlined,
              label: context.l10n.createArchive,
              onTap: () => Navigator.of(context).pop('archive'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (kind == null || !mounted) return;
    if (kind == 'archive') {
      if (state.entries.isEmpty) return;
      final CreateArchiveRequest? request = await showCreateArchiveSheet(
        context,
        sources: state.entries,
        suggestedName: _vm.suggestedArchiveName(),
        destinationDir: state.path,
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
      return;
    }
    final bool folder = kind == 'folder';
    final String? name = await showTextInputDialog(
      context,
      title: folder ? context.l10n.createFolderTitle : context.l10n.createFileTitle,
      hint: folder ? context.l10n.folderNameHint : context.l10n.fileNameHint,
      confirmLabel: context.l10n.create,
      selectStem: false,
      exists: _vm.nameExists,
    );
    if (name == null || !mounted) return;
    final result = folder ? await _vm.createFolder(name) : await _vm.createFile(name);
    if (!mounted) return;
    result.fold(
      onSuccess: (_) => context.showSnack(folder ? context.l10n.folderCreated : context.l10n.fileCreated),
      onFailure: (Failure f) => context.showSnack(_failureText(f)),
    );
  }

  String _failureText(Failure f) => switch (f) {
        PermissionFailure() => context.l10n.errorPermission,
        NotFoundFailure() => context.l10n.errorNotFound,
        AlreadyExistsFailure() => context.l10n.errorExists,
        DiskFullFailure() => context.l10n.errorDiskFull,
        NameTooLongFailure() => context.l10n.errorNameTooLong,
        InvalidNameFailure() => context.l10n.invalidName,
        _ => context.l10n.errorIo,
      };

  @override
  Widget build(BuildContext context) {
    final BrowserState state = ref.watch(browserProvider(widget.path));
    return PopScope<Object?>(
      canPop: _canPopDirectly(state),
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _handleBack(state);
      },
      child: Scaffold(
        appBar: state.selecting
            ? _SelectionAppBar(
                count: state.selected.length,
                allSelected: state.allSelected,
                onClose: _vm.clearSelection,
                onSelectAll: _vm.selectAll,
                onInvert: _vm.invertSelection,
              )
            : _BrowserAppBar(
                state: state,
                searching: _searching,
                controller: _searchController,
                onSearchToggle: () {
                  setState(() => _searching = !_searching);
                  if (!_searching) {
                    _searchController.clear();
                    _vm.setQuery('');
                  }
                },
                onQueryChanged: _vm.setQuery,
                onToggleView: _vm.toggleViewMode,
                onSort: () => showSortSheet(
                  context,
                  sort: state.sort,
                  onChanged: _vm.setSort,
                  showHidden: state.showHidden,
                  onToggleHidden: _vm.toggleHidden,
                ),
                onMenu: (String value) => _onMenu(value, state),
                onBack: () => _goBack(state),
                atVolumeRoot: _atVolumeRoot(state),
              ),
        body: Column(
          children: <Widget>[
            BreadcrumbBar(
              path: state.path,
              volume: state.volume,
              onNavigate: (String target) {
                if (target == state.path) return;
                context.pushReplacement(AppRoutes.withPath(AppRoutes.browse, target));
              },
            ),
            if (!state.selecting)
              FolderStatsBar(
                itemCount: state.totalCount,
                volume: state.volume,
                filterCount: state.query.isEmpty ? 0 : 1,
                onFilter: () => showSortSheet(
                  context,
                  sort: state.sort,
                  onChanged: _vm.setSort,
                  showHidden: state.showHidden,
                  onToggleHidden: _vm.toggleHidden,
                ),
              )
            else
              _SelectionSummary(state: state),
            Expanded(child: _body(state)),
          ],
        ),
        bottomNavigationBar: state.selecting
            ? SelectionActionBar(
                onCopy: () => _selectionCopyOrMove(state, move: false),
                onMove: () => _selectionCopyOrMove(state, move: true),
                onDelete: () => _selectionDelete(state),
                onShare: () => _selectionShare(state),
                onMore: () => _selectionMore(state),
                shareEnabled: state.selectedFileCount > 0,
              )
            : null,
        floatingActionButton: state.selecting || state.restricted
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton(
                  onPressed: () => _create(state),
                  tooltip: context.l10n.create,
                  child: const Icon(Icons.add),
                ),
              ),
      ),
    );
  }

  void _onMenu(String value, BrowserState state) {
    switch (value) {
      case 'select':
        if (state.entries.isNotEmpty) _vm.startSelection(state.entries.first.path);
      case 'hidden':
        _vm.toggleHidden();
      case 'refresh':
        _vm.refresh();
    }
  }

  Widget _body(BrowserState state) {
    if (state.restricted) {
      return FvEmptyState(
        icon: Icons.lock_outline,
        title: context.l10n.restrictedFolderTitle,
        message: context.l10n.restrictedFolderBody,
      );
    }
    final Failure? failure = state.failure;
    if (failure != null) {
      return FvEmptyState(
        icon: Icons.error_outline,
        title: context.l10n.cannotReadFolder,
        message: _failureText(failure),
        action: FvTonalButton(label: context.l10n.retry, onPressed: _vm.refresh),
      );
    }
    if (state.loading && state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.visible.isEmpty) {
      return RefreshIndicator(
        onRefresh: _vm.refresh,
        child: ListView(
          children: <Widget>[
            SizedBox(height: context.screen.height * 0.08),
            FvEmptyState(
              icon: Icons.folder_open,
              title: state.query.isEmpty ? context.l10n.emptyFolderTitle : context.l10n.noResultsTitle,
              message: state.query.isEmpty ? context.l10n.emptyFolderBody : context.l10n.noResultsBody,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _vm.refresh,
      child: state.viewMode == ViewMode.grid ? _grid(state) : _list(state),
    );
  }

  Widget _list(BrowserState state) {
    final List<FileEntry> folders = state.folders;
    final List<FileEntry> files = state.files;
    return CustomScrollView(
      slivers: <Widget>[
        if (folders.isNotEmpty) ...<Widget>[
          SliverToBoxAdapter(
            child: FvSectionHeader(
              title: context.l10n.folders,
              count: folders.length,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              trailing: state.selecting
                  ? Text(
                      context.l10n.foldersMarked(state.selectedFolderCount),
                      style: context.texts.labelMedium?.copyWith(color: context.tokens.amber),
                    )
                  : TextButton(
                      onPressed: folders.isEmpty ? null : () => _vm.startSelection(folders.first.path),
                      child: Text(context.l10n.select),
                    ),
            ),
          ),
          _sliverCard(folders, state),
        ],
        if (files.isNotEmpty) ...<Widget>[
          SliverToBoxAdapter(
            child: FvSectionHeader(
              title: context.l10n.files,
              count: files.length,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              trailing: state.selecting
                  ? Text(
                      context.l10n.filesMarked(state.selectedFileCount),
                      style: context.texts.labelMedium?.copyWith(color: context.tokens.amber),
                    )
                  : null,
            ),
          ),
          _sliverCard(files, state),
        ],
        SliverToBoxAdapter(child: SizedBox(height: 140 + context.padding.bottom)),
      ],
    );
  }

  Widget _sliverCard(List<FileEntry> entries, BrowserState state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: context.isDark ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.tokens.cardBorder),
        ),
        sliver: SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (BuildContext context, int i) {
            final FileEntry e = entries[i];
            return FvFileListTile(
              entry: e,
              selecting: state.selecting,
              selected: state.selected.contains(e.path),
              showDivider: i != entries.length - 1,
              onTap: () => _open(e, state),
              onLongPress: () => state.selecting ? _vm.toggle(e.path) : _vm.startSelection(e.path),
              onMore: state.selecting ? null : () => _showActions(e, state),
            );
          },
        ),
      ),
    );
  }

  Widget _grid(BrowserState state) {
    final List<FileEntry> entries = state.visible;
    final double width = context.screen.width;
    final int columns = width >= 900 ? 5 : width >= 600 ? 4 : 3;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 140 + context.padding.bottom),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: entries.length,
      itemBuilder: (BuildContext context, int i) {
        final FileEntry e = entries[i];
        return FvFileGridTile(
          entry: e,
          selecting: state.selecting,
          selected: state.selected.contains(e.path),
          onTap: () => _open(e, state),
          onLongPress: () => state.selecting ? _vm.toggle(e.path) : _vm.startSelection(e.path),
        );
      },
    );
  }
}

class _BrowserAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BrowserAppBar({
    required this.state,
    required this.searching,
    required this.controller,
    required this.onSearchToggle,
    required this.onQueryChanged,
    required this.onToggleView,
    required this.onSort,
    required this.onMenu,
    required this.onBack,
    required this.atVolumeRoot,
  });

  final BrowserState state;
  final bool searching;
  final TextEditingController controller;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onToggleView;
  final VoidCallback onSort;
  final ValueChanged<String> onMenu;
  final VoidCallback onBack;
  final bool atVolumeRoot;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    if (searching) {
      return FvAppBar(
        leading: FvBackButton(icon: Icons.arrow_back, onPressed: onSearchToggle),
        titleWidget: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: controller,
            autofocus: true,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: context.l10n.searchInCurrentFolder,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
      );
    }
    final String name = state.path.split('/').where((String s) => s.isNotEmpty).lastOrNull ??
        context.l10n.internalStorage;
    final bool isVolumeRoot = atVolumeRoot;
    return FvAppBar(
      leading: isVolumeRoot && !Navigator.of(context).canPop()
          ? null
          : FvBackButton(onPressed: onBack),
      title: isVolumeRoot ? (state.volume?.name ?? name) : name,
      subtitle: state.loading
          ? context.l10n.loading
          : '${context.l10n.itemCount(state.totalCount)} • ${FileSizeFormatter.format(state.freeBytes)} ${context.l10n.free}',
      actions: <Widget>[
        FvIconButton(icon: Icons.search, tooltip: context.l10n.search, onPressed: onSearchToggle),
        FvIconButton(
          icon: state.viewMode == ViewMode.list ? Icons.grid_view_outlined : Icons.view_list_outlined,
          tooltip: state.viewMode == ViewMode.list ? context.l10n.gridView : context.l10n.listView,
          onPressed: onToggleView,
        ),
        FvIconButton(icon: Icons.swap_vert, tooltip: context.l10n.sortBy, onPressed: onSort),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: onMenu,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'select', child: Text(context.l10n.select)),
            PopupMenuItem<String>(
              value: 'hidden',
              child: Text(state.showHidden ? context.l10n.hideHiddenFiles : context.l10n.showHiddenFiles),
            ),
            PopupMenuItem<String>(value: 'refresh', child: Text(context.l10n.retry)),
          ],
        ),
      ],
    );
  }
}

class _SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SelectionAppBar({
    required this.count,
    required this.allSelected,
    required this.onClose,
    required this.onSelectAll,
    required this.onInvert,
  });

  final int count;
  final bool allSelected;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onInvert;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return FvAppBar(
      backgroundColor:
          context.isDark ? context.colors.surfaceContainer : context.colors.primaryFixed.withValues(alpha: 0.45),
      leading: FvIconButton(
        icon: Icons.close,
        tooltip: context.l10n.clearSelection,
        color: context.colors.onSurface,
        onPressed: onClose,
      ),
      title: context.l10n.selectedCount(count),
      actions: <Widget>[
        FvIconButton(
          icon: allSelected ? Icons.deselect : Icons.select_all,
          tooltip: allSelected ? context.l10n.clearSelection : context.l10n.selectAll,
          onPressed: allSelected ? onClose : onSelectAll,
        ),
        FvIconButton(
          icon: Icons.flip_to_back,
          tooltip: context.l10n.invertSelection,
          onPressed: onInvert,
        ),
      ],
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.isDark ? context.colors.surfaceContainerLow : context.colors.primaryFixed.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.isDark ? context.colors.primaryContainer : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.inventory_2_outlined, size: 18, color: context.colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(context.l10n.totalSelectedVolume, style: context.texts.titleSmall),
                  Text(
                    context.l10n.acrossItems(
                      FileSizeFormatter.format(state.selectedBytes),
                      state.selected.length,
                    ),
                    style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            FvCountBadge(context.l10n.ready, amber: true),
          ],
        ),
      ),
    );
  }
}
