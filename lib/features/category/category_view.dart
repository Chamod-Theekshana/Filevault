import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/folder_picker_sheet.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/core/widgets/fv_file_tile.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:filevault/features/browser/widgets/file_actions_sheet.dart';
import 'package:filevault/features/home/widgets/home_sections.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:filevault/features/viewer/open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class CategoryState {
  const CategoryState({
    this.entries = const <FileEntry>[],
    this.loading = true,
    this.sort = const SortSpec(field: SortField.date, direction: SortDirection.desc),
    this.viewMode = ViewMode.list,
    this.selected = const <String>{},
    this.indexed = true,
  });

  final List<FileEntry> entries;
  final bool loading;
  final SortSpec sort;
  final ViewMode viewMode;
  final Set<String> selected;
  final bool indexed;

  bool get selecting => selected.isNotEmpty;
  int get totalBytes => entries.fold(0, (int a, FileEntry e) => a + e.size);

  CategoryState copyWith({
    List<FileEntry>? entries,
    bool? loading,
    SortSpec? sort,
    ViewMode? viewMode,
    Set<String>? selected,
    bool? indexed,
  }) {
    return CategoryState(
      entries: entries ?? this.entries,
      loading: loading ?? this.loading,
      sort: sort ?? this.sort,
      viewMode: viewMode ?? this.viewMode,
      selected: selected ?? this.selected,
      indexed: indexed ?? this.indexed,
    );
  }
}

final AutoDisposeNotifierProviderFamily<CategoryViewModel, CategoryState, FileCategory>
    categoryProvider =
    NotifierProvider.autoDispose.family<CategoryViewModel, CategoryState, FileCategory>(
  CategoryViewModel.new,
);

class CategoryViewModel extends AutoDisposeFamilyNotifier<CategoryState, FileCategory> {
  bool _disposed = false;

  @override
  CategoryState build(FileCategory arg) {
    ref.onDispose(() => _disposed = true);
    ref.listen(operationFinishedProvider, (_, _) => load());
    Future<void>.microtask(load);
    return CategoryState(
      viewMode: arg.isMedia ? ViewMode.grid : ViewMode.list,
    );
  }

  void _set(CategoryState next) {
    if (_disposed) return;
    state = next;
  }

  Future<void> load() async {
    if (_disposed) return;
    _set(state.copyWith(loading: true));
    final bool empty = await ref.read(indexRepositoryProvider).isEmpty;
    if (_disposed) return;
    if (empty) {
      _set(state.copyWith(loading: false, indexed: false, entries: <FileEntry>[]));
      return;
    }
    final List<FileEntry> files =
        await ref.read(indexRepositoryProvider).filesInCategory(arg, limit: 3000);
    // Drop entries whose file disappeared since the last scan.
    final List<FileEntry> alive = <FileEntry>[];
    for (final FileEntry e in files) {
      if (_disposed) return;
      if (await ref.read(fileRepositoryProvider).exists(e.path)) alive.add(e);
    }
    _set(state.copyWith(
      entries: state.sort.apply(alive),
      loading: false,
      indexed: true,
    ));
  }

  Future<void> buildIndex() async {
    _set(state.copyWith(loading: true));
    await ref
        .read(indexRepositoryProvider)
        .rebuild(includeHidden: ref.read(settingsProvider).showHiddenFiles);
    if (_disposed) return;
    await load();
  }

  void setSort(SortSpec sort) =>
      state = state.copyWith(sort: sort, entries: sort.apply(state.entries));

  void toggleViewMode() => state = state.copyWith(
        viewMode: state.viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list,
      );

  void toggle(String path) {
    final Set<String> next = Set<String>.of(state.selected);
    if (!next.remove(path)) next.add(path);
    state = state.copyWith(selected: next);
  }

  void selectAll() =>
      state = state.copyWith(selected: state.entries.map((FileEntry e) => e.path).toSet());

  void clearSelection() => state = state.copyWith(selected: <String>{});
}

/// Virtual folder listing every file of one category across all storage.
class CategoryView extends ConsumerWidget {
  const CategoryView({super.key, required this.category});

  final FileCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CategoryState state = ref.watch(categoryProvider(category));
    final CategoryViewModel vm = ref.read(categoryProvider(category).notifier);
    final String title = categoryLabel(context.l10n, category);
    return Scaffold(
      appBar: FvAppBar(
        leading: FvBackButton(
          onPressed: state.selecting ? vm.clearSelection : null,
          icon: state.selecting ? Icons.close : Icons.arrow_back,
        ),
        title: state.selecting ? context.l10n.selectedCount(state.selected.length) : title,
        subtitle: state.selecting
            ? null
            : '${context.l10n.itemCount(state.entries.length)} • ${FileSizeFormatter.format(state.totalBytes)}',
        actions: <Widget>[
          if (state.selecting)
            FvIconButton(
              icon: Icons.select_all,
              tooltip: context.l10n.selectAll,
              onPressed: vm.selectAll,
            )
          else ...<Widget>[
            FvIconButton(
              icon: state.viewMode == ViewMode.list ? Icons.grid_view_outlined : Icons.view_list_outlined,
              tooltip: state.viewMode == ViewMode.list ? context.l10n.gridView : context.l10n.listView,
              onPressed: vm.toggleViewMode,
            ),
            FvIconButton(
              icon: Icons.swap_vert,
              tooltip: context.l10n.sortBy,
              onPressed: () => showSortSheet(context, sort: state.sort, onChanged: vm.setSort),
            ),
          ],
        ],
      ),
      body: _body(context, ref, state, vm),
      bottomNavigationBar: state.selecting
          ? SelectionActionBar(
              onCopy: () => _transfer(context, ref, state, vm, move: false),
              onMove: () => _transfer(context, ref, state, vm, move: true),
              onDelete: () async {
                final List<String> paths = state.selected.toList();
                final bool confirm = ref.read(settingsProvider).confirmBeforeDelete;
                if (confirm) {
                  final bool ok = await showConfirmDialog(
                    context,
                    title: context.l10n.deleteTitle,
                    message: context.l10n.deleteBody(paths.length),
                    confirmLabel: context.l10n.moveToTrash,
                    destructive: true,
                    icon: Icons.delete_outline,
                  );
                  if (!ok || !context.mounted) return;
                }
                ref.read(operationsProvider.notifier).enqueueTrash(paths);
                vm.clearSelection();
              },
              onShare: () async {
                final List<XFile> files =
                    state.selected.map((String p) => XFile(p)).toList();
                if (files.isEmpty) return;
                await SharePlus.instance.share(ShareParams(files: files));
              },
              onMore: () => _more(context, ref, state, vm),
            )
          : null,
    );
  }

  Future<void> _transfer(
    BuildContext context,
    WidgetRef ref,
    CategoryState state,
    CategoryViewModel vm, {
    required bool move,
  }) async {
    final List<String> sources = state.selected.toList();
    if (sources.isEmpty) return;
    final String? destination = await showFolderPicker(
      context,
      confirmLabel: move ? context.l10n.moveHere : context.l10n.copyHere,
    );
    if (destination == null || !context.mounted) return;
    final OperationsController ops = ref.read(operationsProvider.notifier);
    if (move) {
      ops.enqueueMove(sources, destination);
    } else {
      ops.enqueueCopy(sources, destination);
    }
    vm.clearSelection();
  }

  Future<void> _more(
    BuildContext context,
    WidgetRef ref,
    CategoryState state,
    CategoryViewModel vm,
  ) async {
    final String? action = await showSelectionMoreSheet(context, canCompress: false);
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'selectAll':
        vm.selectAll();
      case 'favorite':
        for (final FileEntry e in state.entries) {
          if (!context.mounted) return;
          if (state.selected.contains(e.path)) {
            await ref.read(collectionsRepositoryProvider).addFavorite(e);
          }
        }
        if (context.mounted) context.showSnack(context.l10n.addedToFavorites);
        vm.clearSelection();
      case 'vault':
        final List<String> files = state.selected.toList();
        final bool configured = await ref.read(vaultRepositoryProvider).isConfigured();
        if (!context.mounted) return;
        if (!configured) {
          context.push(AppRoutes.vaultSetup);
          return;
        }
        if (!ref.read(vaultRepositoryProvider).isUnlocked) {
          context.push(AppRoutes.vault, extra: <String, Object?>{'pendingAdd': files});
          vm.clearSelection();
          return;
        }
        ref.read(operationsProvider.notifier).enqueueEncrypt(files);
        vm.clearSelection();
      case 'deleteForever':
        final bool ok = await showConfirmDialog(
          context,
          title: context.l10n.deletePermanentlyTitle,
          message: context.l10n.deletePermanentlyBody(state.selected.length),
          confirmLabel: context.l10n.deletePermanently,
          destructive: true,
          icon: Icons.delete_forever_outlined,
        );
        if (!ok || !context.mounted) return;
        ref.read(operationsProvider.notifier).enqueueDelete(state.selected.toList());
        vm.clearSelection();
    }
  }

  Widget _body(BuildContext context, WidgetRef ref, CategoryState state, CategoryViewModel vm) {
    if (!state.indexed && !state.loading) {
      return FvEmptyState(
        icon: Icons.radar,
        title: context.l10n.indexEmptyTitle,
        message: context.l10n.indexEmptyBody,
        action: FvFilledButton(
          label: context.l10n.scan,
          icon: Icons.search,
          expand: false,
          onPressed: vm.buildIndex,
        ),
      );
    }
    if (state.loading && state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.entries.isEmpty) {
      return FvEmptyState(
        icon: Icons.folder_open,
        title: context.l10n.emptyFolderTitle,
        message: context.l10n.noResultsBody,
        action: FvTonalButton(label: context.l10n.rescan, onPressed: vm.buildIndex),
      );
    }
    if (state.viewMode == ViewMode.grid) {
      final double width = context.screen.width;
      final int columns = width >= 900 ? 5 : width >= 600 ? 4 : 3;
      return RefreshIndicator(
        onRefresh: vm.load,
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 120 + context.padding.bottom),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: state.entries.length,
          itemBuilder: (BuildContext context, int i) {
            final FileEntry e = state.entries[i];
            return FvFileGridTile(
              entry: e,
              selecting: state.selecting,
              selected: state.selected.contains(e.path),
              onTap: () => state.selecting
                  ? vm.toggle(e.path)
                  : openFileEntry(context, ref, e, siblings: state.entries),
              onLongPress: () => vm.toggle(e.path),
            );
          },
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 120 + context.padding.bottom),
        itemCount: state.entries.length,
        itemBuilder: (BuildContext context, int i) {
          final FileEntry e = state.entries[i];
          return FvFileListTile(
            entry: e,
            selecting: state.selecting,
            selected: state.selected.contains(e.path),
            subtitle: '${FileSizeFormatter.format(e.size)}  •  ${e.parentPath}',
            onTap: () => state.selecting
                ? vm.toggle(e.path)
                : openFileEntry(context, ref, e, siblings: state.entries),
            onLongPress: () => vm.toggle(e.path),
            onMore: state.selecting
                ? null
                : () async {
                    final FileActionResult r =
                        await showFileActionsSheet(context, ref, e, siblings: state.entries);
                    if (r == FileActionResult.changed) await vm.load();
                  },
          );
        },
      ),
    );
  }
}
