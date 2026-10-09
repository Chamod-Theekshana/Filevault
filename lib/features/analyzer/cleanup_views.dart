import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/core/widgets/fv_file_tile.dart';
import 'package:filevault/domain/models/analyzer_models.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/viewer/open_file.dart';
import 'package:filevault/core/utils/ui_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final AutoDisposeFutureProvider<List<FileEntry>> largeFilesProvider =
    FutureProvider.autoDispose<List<FileEntry>>((Ref ref) {
  ref.watch(operationFinishedProvider);
  return ref.watch(analyzerRepositoryProvider).largeFiles();
});

/// Largest files on the device, newest first.
class LargeFilesView extends ConsumerStatefulWidget {
  const LargeFilesView({super.key});

  @override
  ConsumerState<LargeFilesView> createState() => _LargeFilesViewState();
}

class _LargeFilesViewState extends ConsumerState<LargeFilesView> {
  final Set<String> _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<FileEntry>> files = ref.watch(largeFilesProvider);
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: context.l10n.largeFiles,
        subtitle: files.valueOrNull == null
            ? null
            : context.l10n.largeFilesSub(files.value!.length, '100 MB'),
      ),
      body: files.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text(context.l10n.somethingWentWrong)),
        data: (List<FileEntry> list) {
          if (list.isEmpty) {
            return FvEmptyState(
              icon: Icons.inventory_2_outlined,
              title: context.l10n.largeFilesEmpty,
              message: context.l10n.optimizationSub,
            );
          }
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 140 + context.padding.bottom),
            itemCount: list.length,
            itemBuilder: (BuildContext context, int i) {
              final FileEntry e = list[i];
              return FvFileListTile(
                entry: e,
                selecting: _selected.isNotEmpty,
                selected: _selected.contains(e.path),
                subtitle: '${FileSizeFormatter.format(e.size)}  •  ${e.parentPath}',
                onTap: () => _selected.isEmpty
                    ? openFileEntry(context, ref, e)
                    : setState(() {
                        if (!_selected.remove(e.path)) _selected.add(e.path);
                      }),
                onLongPress: () => setState(() {
                  if (!_selected.remove(e.path)) _selected.add(e.path);
                }),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : ReserveBottomSpace(
              height: 76,
              child: _CleanupBar(
              label: context.l10n.deleteSelected(_selected.length),
              onPressed: () async {
                final bool ok = await showConfirmDialog(
                  context,
                  title: context.l10n.deleteTitle,
                  message: context.l10n.deleteBody(_selected.length),
                  confirmLabel: context.l10n.moveToTrash,
                  destructive: true,
                  icon: Icons.delete_outline,
                );
                if (!ok) return;
                ref.read(operationsProvider.notifier).enqueueTrash(_selected.toList());
                setState(_selected.clear);
              },
            ),
            ),
    );
  }
}

final AutoDisposeFutureProvider<List<DuplicateGroup>> duplicatesProvider =
    FutureProvider.autoDispose<List<DuplicateGroup>>((Ref ref) {
  ref.watch(operationFinishedProvider);
  return ref.watch(analyzerRepositoryProvider).findDuplicates();
});

/// Duplicate finder: groups by SHA-256, keeps one copy by default.
class DuplicatesView extends ConsumerStatefulWidget {
  const DuplicatesView({super.key});

  @override
  ConsumerState<DuplicatesView> createState() => _DuplicatesViewState();
}

class _DuplicatesViewState extends ConsumerState<DuplicatesView> {
  final Set<String> _selected = <String>{};

  void _selectAllButFirst(List<DuplicateGroup> groups) {
    setState(() {
      _selected.clear();
      for (final DuplicateGroup g in groups) {
        for (final FileEntry e in g.files.skip(1)) {
          _selected.add(e.path);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<DuplicateGroup>> groups = ref.watch(duplicatesProvider);
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: context.l10n.duplicateFiles,
        subtitle: groups.valueOrNull == null
            ? context.l10n.scanning
            : context.l10n.recoverable(
                FileSizeFormatter.format(
                  groups.value!.fold(0, (int a, DuplicateGroup g) => a + g.wastedBytes),
                ),
              ),
        actions: <Widget>[
          if (groups.valueOrNull != null && groups.value!.isNotEmpty)
            TextButton(
              onPressed: () => _selectAllButFirst(groups.value!),
              child: Text(context.l10n.selectAllButOne),
            ),
        ],
      ),
      body: groups.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(context.l10n.scanning, style: context.texts.bodyMedium),
            ],
          ),
        ),
        error: (Object e, _) => Center(child: Text(context.l10n.somethingWentWrong)),
        data: (List<DuplicateGroup> list) {
          if (list.isEmpty) {
            return FvEmptyState(
              icon: Icons.verified_outlined,
              title: context.l10n.duplicatesEmpty,
              message: context.l10n.optimizationSub,
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 140 + context.padding.bottom),
            itemCount: list.length,
            itemBuilder: (BuildContext context, int gi) {
              final DuplicateGroup g = list[gi];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FvCard(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.copy_all_outlined, size: 18, color: context.colors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.duplicateGroup(
                                  g.files.length,
                                  FileSizeFormatter.format(g.size),
                                ),
                                style: context.texts.titleSmall,
                              ),
                            ),
                            Text(
                              '+${FileSizeFormatter.format(g.wastedBytes)}',
                              style: context.texts.labelMedium?.copyWith(color: context.tokens.amber),
                            ),
                          ],
                        ),
                      ),
                      for (int i = 0; i < g.files.length; i++)
                        FvFileListTile(
                          entry: g.files[i],
                          selecting: true,
                          selected: _selected.contains(g.files[i].path),
                          showDivider: i != g.files.length - 1,
                          subtitle: g.files[i].parentPath,
                          badges: i == 0
                              ? <Widget>[FvCountBadge(context.l10n.keepNewest)]
                              : const <Widget>[],
                          onTap: () => setState(() {
                            if (!_selected.remove(g.files[i].path)) _selected.add(g.files[i].path);
                          }),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : ReserveBottomSpace(
              height: 76,
              child: _CleanupBar(
              label: context.l10n.deleteSelected(_selected.length),
              onPressed: () async {
                final bool ok = await showConfirmDialog(
                  context,
                  title: context.l10n.deleteTitle,
                  message: context.l10n.deleteBody(_selected.length),
                  confirmLabel: context.l10n.moveToTrash,
                  destructive: true,
                  icon: Icons.delete_outline,
                );
                if (!ok) return;
                ref.read(operationsProvider.notifier).enqueueTrash(_selected.toList());
                setState(_selected.clear);
              },
            ),
            ),
    );
  }
}

final AutoDisposeFutureProvider<JunkReport> junkProvider =
    FutureProvider.autoDispose<JunkReport>((Ref ref) {
  return ref.watch(analyzerRepositoryProvider).scanJunk();
});

/// Junk, cache and empty-folder cleaner with a preview before deletion.
class JunkCleanerView extends ConsumerStatefulWidget {
  const JunkCleanerView({super.key});

  @override
  ConsumerState<JunkCleanerView> createState() => _JunkCleanerViewState();
}

class _JunkCleanerViewState extends ConsumerState<JunkCleanerView> {
  final Set<String> _selected = <String>{};
  bool _initialised = false;

  String _kindLabel(JunkKind kind) => switch (kind) {
        JunkKind.cache => context.l10n.junkCacheKind,
        JunkKind.temp => context.l10n.junkTempKind,
        JunkKind.log => context.l10n.junkLogKind,
        JunkKind.thumbnail => context.l10n.junkThumbKind,
        JunkKind.emptyFolder => context.l10n.junkEmptyFolderKind,
      };

  @override
  Widget build(BuildContext context) {
    final AsyncValue<JunkReport> report = ref.watch(junkProvider);
    final JunkReport? data = report.valueOrNull;
    if (data != null && !_initialised) {
      _initialised = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selected.addAll(data.items.map((JunkItem i) => i.path)));
        }
      });
    }
    final int selectedBytes = data == null
        ? 0
        : data.items
            .where((JunkItem i) => _selected.contains(i.path))
            .fold(0, (int a, JunkItem i) => a + i.bytes);
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: context.l10n.junkCache,
        subtitle: data == null
            ? context.l10n.scanning
            : '${context.l10n.itemCount(data.items.length)} • ${FileSizeFormatter.format(data.totalBytes)}',
        actions: <Widget>[
          FvIconButton(
            icon: Icons.refresh,
            tooltip: context.l10n.rescan,
            onPressed: () {
              _initialised = false;
              _selected.clear();
              ref.invalidate(junkProvider);
            },
          ),
        ],
      ),
      body: report.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(context.l10n.scanning, style: context.texts.bodyMedium),
            ],
          ),
        ),
        error: (Object e, _) => Center(child: Text(context.l10n.somethingWentWrong)),
        data: (JunkReport r) {
          if (r.items.isEmpty) {
            return FvEmptyState(
              icon: Icons.cleaning_services_outlined,
              title: context.l10n.junkEmpty,
              message: context.l10n.optimizationSub,
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 140 + context.padding.bottom),
            itemCount: r.items.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FvInfoBanner(
                    tone: FvBannerTone.amber,
                    icon: Icons.warning_amber_outlined,
                    title: context.l10n.junkSub,
                    subtitle: context.l10n.cleanJunkBody(r.items.length, FileSizeFormatter.format(r.totalBytes)),
                  ),
                );
              }

              final int i = index - 1;
              final bool isFirst = i == 0;
              final bool isLast = i == r.items.length - 1;
              final Radius radius = const Radius.circular(18);

              return DecoratedBox(
                decoration: BoxDecoration(
                  color: context.isDark ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.vertical(
                    top: isFirst ? radius : Radius.zero,
                    bottom: isLast ? radius : Radius.zero,
                  ),
                  border: Border(
                    left: BorderSide(color: context.tokens.cardBorder),
                    right: BorderSide(color: context.tokens.cardBorder),
                    top: isFirst ? BorderSide(color: context.tokens.cardBorder) : BorderSide.none,
                    bottom: isLast ? BorderSide(color: context.tokens.cardBorder) : BorderSide.none,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: isFirst ? radius : Radius.zero,
                    bottom: isLast ? radius : Radius.zero,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: _JunkRow(
                      item: r.items[i],
                      kindLabel: _kindLabel(r.items[i].kind),
                      selected: _selected.contains(r.items[i].path),
                      last: isLast,
                      onTap: () => setState(() {
                        if (!_selected.remove(r.items[i].path)) _selected.add(r.items[i].path);
                      }),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _selected.isEmpty || data == null
          ? null
          : ReserveBottomSpace(
              height: 76,
              child: _CleanupBar(
              label: context.l10n.cleanSelected(FileSizeFormatter.format(selectedBytes)),
              icon: Icons.cleaning_services_outlined,
              onPressed: () async {
                final List<JunkItem> items =
                    data.items.where((JunkItem i) => _selected.contains(i.path)).toList();
                final bool ok = await showConfirmDialog(
                  context,
                  title: context.l10n.cleanJunkTitle,
                  message: context.l10n.cleanJunkBody(
                    items.length,
                    FileSizeFormatter.format(selectedBytes),
                  ),
                  confirmLabel: context.l10n.clean,
                  destructive: true,
                  icon: Icons.cleaning_services_outlined,
                );
                if (!ok) return;
                final int freed = await ref.read(analyzerRepositoryProvider).deleteJunk(items);
                if (!context.mounted) return;
                context.showSnack('${context.l10n.cleaned} • ${FileSizeFormatter.format(freed)}');
                _initialised = false;
                setState(_selected.clear);
                ref.invalidate(junkProvider);
              },
            ),
            ),
    );
  }
}

class _JunkRow extends StatelessWidget {
  const _JunkRow({
    required this.item,
    required this.kindLabel,
    required this.selected,
    required this.last,
    required this.onTap,
  });

  final JunkItem item;
  final String kindLabel;
  final bool selected;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          child: Row(
            children: <Widget>[
              FvSelectCircle(selected: selected),
              const SizedBox(width: 12),
              FvCategoryTile(
                category: item.kind == JunkKind.emptyFolder ? FileCategory.folders : FileCategory.trash,
                icon: switch (item.kind) {
                  JunkKind.cache => Icons.cached,
                  JunkKind.temp => Icons.hourglass_empty,
                  JunkKind.log => Icons.receipt_long_outlined,
                  JunkKind.thumbnail => Icons.image_outlined,
                  JunkKind.emptyFolder => Icons.folder_off_outlined,
                },
                size: 40,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.texts.titleSmall),
                    Text(
                      '$kindLabel  •  ${item.path}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.bytes == 0 ? '—' : FileSizeFormatter.format(item.bytes),
                style: context.texts.labelMedium?.copyWith(
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CleanupBar extends StatelessWidget {
  const _CleanupBar({required this.label, required this.onPressed, this.icon = Icons.delete_outline});

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.isDark ? context.colors.surfaceContainerHigh : context.colors.surfaceContainerLowest,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.tokens.cardBorder)),
        ),
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + context.padding.bottom),
        child: FvFilledButton(label: label, icon: icon, onPressed: onPressed),
      ),
    );
  }
}
