import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:filevault/domain/models/trash_item.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:filevault/core/utils/ui_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TrashState {
  const TrashState({
    this.items = const <TrashItem>[],
    this.selected = const <int>{},
    this.loading = true,
    this.totalBytes = 0,
    this.freeBytes = 0,
  });

  final List<TrashItem> items;
  final Set<int> selected;
  final bool loading;
  final int totalBytes;
  final int freeBytes;

  bool get selecting => selected.isNotEmpty;

  List<TrashItem> get selectedItems =>
      items.where((TrashItem i) => selected.contains(i.id)).toList(growable: false);

  TrashState copyWith({
    List<TrashItem>? items,
    Set<int>? selected,
    bool? loading,
    int? totalBytes,
    int? freeBytes,
  }) {
    return TrashState(
      items: items ?? this.items,
      selected: selected ?? this.selected,
      loading: loading ?? this.loading,
      totalBytes: totalBytes ?? this.totalBytes,
      freeBytes: freeBytes ?? this.freeBytes,
    );
  }
}

final AutoDisposeNotifierProvider<TrashViewModel, TrashState> trashProvider =
    NotifierProvider.autoDispose<TrashViewModel, TrashState>(TrashViewModel.new);

class TrashViewModel extends AutoDisposeNotifier<TrashState> {
  @override
  TrashState build() {
    ref.listen(operationFinishedProvider, (_, _) => load());
    Future<void>.microtask(load);
    return const TrashState();
  }

  Future<void> load() async {
    final int days = ref.read(settingsProvider).trashAutoCleanDays;
    await ref.read(trashRepositoryProvider).purgeExpired(days);
    final List<TrashItem> items = await ref.read(trashRepositoryProvider).items();
    final int bytes = await ref.read(trashRepositoryProvider).totalBytes();
    final StorageVolume volume = await ref.read(storageRepositoryProvider).primaryVolume();
    state = state.copyWith(
      items: items,
      totalBytes: bytes,
      freeBytes: volume.freeBytes,
      loading: false,
      selected: state.selected.where((int id) => items.any((TrashItem i) => i.id == id)).toSet(),
    );
  }

  void toggle(int id) {
    final Set<int> next = Set<int>.of(state.selected);
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(selected: next);
  }

  void selectAll() => state = state.copyWith(selected: state.items.map((TrashItem i) => i.id).toSet());

  void clearSelection() => state = state.copyWith(selected: <int>{});

  Future<void> restoreSelected() async {
    final List<TrashItem> items = state.selectedItems;
    if (items.isEmpty) return;
    ref.read(operationsProvider.notifier).enqueueRestore(items);
    clearSelection();
  }

  Future<int> deleteSelected() async {
    final List<TrashItem> items = state.selectedItems;
    for (final TrashItem item in items) {
      await ref.read(trashRepositoryProvider).deletePermanently(item);
    }
    clearSelection();
    await load();
    return items.length;
  }

  Future<void> emptyTrash() async {
    await ref.read(trashRepositoryProvider).emptyTrash();
    clearSelection();
    await load();
  }
}

/// Trash screen: auto-purge banner, deleted files, restore/delete actions.
class TrashView extends ConsumerWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TrashState state = ref.watch(trashProvider);
    final TrashViewModel vm = ref.read(trashProvider.notifier);
    final int days = ref.watch(settingsProvider).trashAutoCleanDays;
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: context.l10n.trash,
        subtitle: context.l10n.itemCount(state.items.length),
        actions: <Widget>[
          if (state.items.isNotEmpty) ...<Widget>[
            FvIconButton(
              icon: state.selecting ? Icons.deselect : Icons.select_all,
              tooltip: state.selecting ? context.l10n.clearSelection : context.l10n.selectAll,
              onPressed: state.selecting ? vm.clearSelection : vm.selectAll,
            ),
            FvIconButton(
              icon: Icons.delete_sweep_outlined,
              tooltip: context.l10n.emptyTrash,
              color: context.colors.error,
              onPressed: () async {
                final bool ok = await showConfirmDialog(
                  context,
                  title: context.l10n.emptyTrashTitle,
                  message: context.l10n.emptyTrashBody(state.items.length),
                  confirmLabel: context.l10n.emptyTrash,
                  destructive: true,
                  icon: Icons.delete_forever_outlined,
                );
                if (ok) await vm.emptyTrash();
              },
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? _EmptyTrash(days: days, freeBytes: state.freeBytes)
              : RefreshIndicator(
                  onRefresh: vm.load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 140 + context.padding.bottom),
                    children: <Widget>[
                      FvInfoBanner(
                        icon: Icons.auto_delete_outlined,
                        title: days > 0 ? context.l10n.autoPurgeActive : context.l10n.autoPurgeOff,
                        subtitle: days > 0 ? context.l10n.autoPurgeBody(days) : context.l10n.autoPurgeBodyNever,
                        badge: days > 0 ? FvCountBadge(context.l10n.nDays(days)) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: context.l10n.settings,
                          onPressed: () => context.go(AppRoutes.settings),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FvSectionHeader(
                        title: context.l10n.deletedFiles,
                        uppercase: false,
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                        trailing: state.selecting
                            ? FvCountBadge(context.l10n.selectedCount(state.selected.length), amber: true)
                            : null,
                      ),
                      for (final TrashItem item in state.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TrashRow(
                            item: item,
                            days: days,
                            selected: state.selected.contains(item.id),
                            onTap: () => vm.toggle(item.id),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _TrashStorage(usedBytes: state.totalBytes, freeBytes: state.freeBytes),
                      const SizedBox(height: 12),
                      FvInfoBanner(
                        tone: FvBannerTone.amber,
                        icon: Icons.lightbulb_outline,
                        title: context.l10n.proTip,
                        subtitle: context.l10n.trashProTip,
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: !state.selecting
          ? null
          : ReserveBottomSpace(
              height: 76,
              child: Material(
              color: context.isDark ? context.colors.surfaceContainerHigh : context.colors.surfaceContainerLowest,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.tokens.cardBorder)),
                ),
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + context.padding.bottom),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () async {
                          final bool ok = await showConfirmDialog(
                            context,
                            title: context.l10n.deletePermanentlyTitle,
                            message: context.l10n.deletePermanentlyBody(state.selected.length),
                            confirmLabel: context.l10n.deletePermanently,
                            destructive: true,
                            icon: Icons.delete_forever_outlined,
                          );
                          if (!ok) return;
                          await vm.deleteSelected();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: context.colors.errorContainer,
                          foregroundColor: context.isDark ? Colors.white : context.colors.onErrorContainer,
                          minimumSize: const Size(64, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.delete_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(context.l10n.delete),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FvFilledButton(
                        label: context.l10n.restoreCount(state.selected.length),
                        icon: Icons.restore,
                        onPressed: vm.restoreSelected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
    );
  }
}

class _TrashRow extends StatelessWidget {
  const _TrashRow({
    required this.item,
    required this.days,
    required this.selected,
    required this.onTap,
  });

  final TrashItem item;
  final int days;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int? left = item.daysLeft(days);
    final bool urgent = left != null && left <= 3;
    return FvCard(
      onTap: onTap,
      color: selected
          ? (context.isDark
              ? context.colors.primaryContainer.withValues(alpha: 0.3)
              : context.colors.primaryFixed.withValues(alpha: 0.5))
          : null,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          FvSelectCircle(selected: selected),
          const SizedBox(width: 12),
          FvCategoryTile(category: item.category, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.texts.titleSmall),
                const SizedBox(height: 2),
                Text(
                  context.l10n.fromPath(item.originalPath),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(
                      FileSizeFormatter.format(item.size),
                      style: context.texts.bodySmall?.copyWith(
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.circle, size: 4, color: context.colors.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.deletedAgo(DateFormatter.ago(item.deletedAt)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (left != null) ...<Widget>[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: urgent
                    ? context.colors.errorContainer.withValues(alpha: context.isDark ? 0.45 : 1)
                    : (context.tokens.tonal),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (urgent) ...<Widget>[
                    Icon(Icons.schedule, size: 12, color: context.colors.error),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    context.l10n.daysLeft(left),
                    style: context.texts.labelSmall?.copyWith(
                      color: urgent
                          ? context.colors.error
                          : context.tokens.onTonal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrashStorage extends StatelessWidget {
  const _TrashStorage({required this.usedBytes, required this.freeBytes});

  final int usedBytes;
  final int freeBytes;

  @override
  Widget build(BuildContext context) {
    final double fraction = freeBytes + usedBytes == 0 ? 0 : usedBytes / (freeBytes + usedBytes);
    return FvCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.donut_small_outlined, size: 18, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(context.l10n.trashStorage, style: context.texts.titleSmall),
              const Spacer(),
              Text(
                FileSizeFormatter.format(usedBytes),
                style: context.texts.labelMedium?.copyWith(
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FvSegmentedBar(
            height: 8,
            segments: <(double, Color)>[(fraction.clamp(0.0, 1.0), context.tokens.amber)],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text(
                context.l10n.usedInBin(FileSizeFormatter.format(usedBytes)),
                style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                context.l10n.available(FileSizeFormatter.format(freeBytes)),
                style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTrash extends StatelessWidget {
  const _EmptyTrash({required this.days, required this.freeBytes});

  final int days;
  final int freeBytes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 40 + context.padding.bottom),
      children: <Widget>[
        FvInfoBanner(
          icon: Icons.auto_delete_outlined,
          title: days > 0 ? context.l10n.autoPurgeActive : context.l10n.autoPurgeOff,
          subtitle: days > 0 ? context.l10n.autoPurgeBody(days) : context.l10n.autoPurgeBodyNever,
          badge: days > 0 ? FvCountBadge(context.l10n.nDays(days)) : null,
        ),
        const SizedBox(height: 8),
        FvEmptyState(
          icon: Icons.delete_outline,
          title: context.l10n.trashEmptyTitle,
          message: days > 0 ? context.l10n.trashEmptyBody(days) : context.l10n.trashEmptyBodyNever,
          action: FvTonalButton(
            label: context.l10n.browseFiles,
            icon: Icons.folder_open_outlined,
            onPressed: () => context.go(AppRoutes.browse),
          ),
        ),
        const SizedBox(height: 8),
        _TrashStorage(usedBytes: 0, freeBytes: freeBytes),
        const SizedBox(height: 12),
        FvInfoBanner(
          tone: FvBannerTone.amber,
          icon: Icons.lightbulb_outline,
          title: context.l10n.proTip,
          subtitle: context.l10n.trashProTip,
        ),
      ],
    );
  }
}
