import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/core/widgets/fv_file_tile.dart';
import 'package:filevault/domain/models/collection_items.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/features/browser/widgets/file_actions_sheet.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/viewer/open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final AutoDisposeFutureProvider<List<FileEntry>> favoritesProvider =
    FutureProvider.autoDispose<List<FileEntry>>((Ref ref) async {
  ref.watch(operationFinishedProvider);
  final List<FavoriteItem> items = await ref.watch(collectionsRepositoryProvider).favorites();
  final List<FileEntry> out = <FileEntry>[];
  for (final FavoriteItem f in items) {
    final FileEntry? e = (await ref.read(fileRepositoryProvider).stat(f.path)).valueOrNull;
    if (e != null) out.add(e);
  }
  return out;
});

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<FileEntry>> favorites = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: FvAppBar(leading: const FvBackButton(), title: context.l10n.favorites),
      body: favorites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text(context.l10n.somethingWentWrong)),
        data: (List<FileEntry> entries) {
          if (entries.isEmpty) {
            return FvEmptyState(
              icon: Icons.star_outline,
              title: context.l10n.favoritesEmptyTitle,
              message: context.l10n.favoritesEmptyBody,
            );
          }
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 120 + context.padding.bottom),
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int i) {
              final FileEntry e = entries[i];
              return FvFileListTile(
                entry: e,
                subtitle: e.parentPath,
                onTap: () => openFileEntry(context, ref, e, siblings: entries),
                onMore: () async {
                  await showFileActionsSheet(context, ref, e, siblings: entries);
                  ref.invalidate(favoritesProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}

final AutoDisposeFutureProvider<List<FileEntry>> recentsProvider =
    FutureProvider.autoDispose<List<FileEntry>>((Ref ref) async {
  ref.watch(operationFinishedProvider);
  final List<RecentItem> items =
      await ref.watch(collectionsRepositoryProvider).recents(limit: 60);
  return _resolveFromRef(ref, items.map((RecentItem r) => r.path).toList());
});

Future<List<FileEntry>> _resolveFromRef(Ref ref, List<String> paths) async {
  final List<FileEntry> out = <FileEntry>[];
  for (final String path in paths) {
    final FileEntry? e = (await ref.read(fileRepositoryProvider).stat(path)).valueOrNull;
    if (e != null) out.add(e);
  }
  return out;
}

class RecentsView extends ConsumerWidget {
  const RecentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<FileEntry>> recents = ref.watch(recentsProvider);
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: context.l10n.recentFiles,
        actions: <Widget>[
          FvIconButton(
            icon: Icons.delete_sweep_outlined,
            tooltip: context.l10n.clearRecents,
            onPressed: () async {
              await ref.read(collectionsRepositoryProvider).clearRecents();
              ref.invalidate(recentsProvider);
            },
          ),
        ],
      ),
      body: recents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text(context.l10n.somethingWentWrong)),
        data: (List<FileEntry> entries) {
          if (entries.isEmpty) {
            return FvEmptyState(
              icon: Icons.history,
              title: context.l10n.recentsEmptyTitle,
              message: context.l10n.recentsEmptyBody,
            );
          }
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 120 + context.padding.bottom),
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int i) {
              final FileEntry e = entries[i];
              return FvFileListTile(
                entry: e,
                subtitle: '${DateFormatter.ago(e.modified)}  •  ${e.parentPath}',
                onTap: () => openFileEntry(context, ref, e, siblings: entries),
                onMore: () async {
                  await showFileActionsSheet(context, ref, e, siblings: entries);
                  ref.invalidate(recentsProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TagsData {
  const _TagsData(this.tags, this.counts);
  final List<Tag> tags;
  final Map<int, int> counts;
}

final AutoDisposeFutureProvider<_TagsData> _tagsProvider =
    FutureProvider.autoDispose<_TagsData>((Ref ref) async {
  final List<Tag> tags = await ref.watch(collectionsRepositoryProvider).tags();
  final Map<int, int> counts = await ref.watch(collectionsRepositoryProvider).tagCounts();
  return _TagsData(tags, counts);
});

/// Tag manager: create, rename, recolor and browse tagged files.
class TagsView extends ConsumerWidget {
  const TagsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<_TagsData> data = ref.watch(_tagsProvider);
    return Scaffold(
      appBar: FvAppBar(leading: const FvBackButton(), title: context.l10n.tags),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final String? name = await showTextInputDialog(
            context,
            title: context.l10n.newTag,
            hint: context.l10n.tagName,
            confirmLabel: context.l10n.create,
            validateFileName: false,
          );
          if (name == null) return;
          final int count = data.valueOrNull?.tags.length ?? 0;
          await ref
              .read(collectionsRepositoryProvider)
              .createTag(name, Tag.palette[count % Tag.palette.length]);
          ref.invalidate(_tagsProvider);
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newTag),
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text(context.l10n.somethingWentWrong)),
        data: (_TagsData d) {
          if (d.tags.isEmpty) {
            return FvEmptyState(
              icon: Icons.label_outline,
              title: context.l10n.tagsEmptyTitle,
              message: context.l10n.tagsEmptyBody,
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 140 + context.padding.bottom),
            children: <Widget>[
              FvCard(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < d.tags.length; i++)
                      _TagRow(
                        tag: d.tags[i],
                        count: d.counts[d.tags[i].id] ?? 0,
                        last: i == d.tags.length - 1,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TaggedFilesView(tag: d.tags[i]),
                          ),
                        ),
                        onEdit: () async {
                          final String? name = await showTextInputDialog(
                            context,
                            title: context.l10n.editTag,
                            hint: context.l10n.tagName,
                            initialValue: d.tags[i].name,
                            validateFileName: false,
                          );
                          if (name == null) return;
                          await ref.read(collectionsRepositoryProvider).updateTag(
                                Tag(id: d.tags[i].id, name: name, colorArgb: d.tags[i].colorArgb),
                              );
                          ref.invalidate(_tagsProvider);
                        },
                        onDelete: () async {
                          final bool ok = await showConfirmDialog(
                            context,
                            title: context.l10n.deleteTag,
                            message: d.tags[i].name,
                            confirmLabel: context.l10n.delete,
                            destructive: true,
                          );
                          if (!ok) return;
                          await ref.read(collectionsRepositoryProvider).deleteTag(d.tags[i].id);
                          ref.invalidate(_tagsProvider);
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.count,
    required this.last,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Tag tag;
  final int count;
  final bool last;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      child: ListTile(
        onTap: onOpen,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(tag.colorArgb).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.label, color: Color(tag.colorArgb)),
        ),
        title: Text(tag.name),
        subtitle: Text(context.l10n.taggedFiles(count)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (String v) => v == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'edit', child: Text(context.l10n.editTag)),
            PopupMenuItem<String>(value: 'delete', child: Text(context.l10n.deleteTag)),
          ],
        ),
      ),
    );
  }
}

/// Files carrying one tag.
class TaggedFilesView extends ConsumerWidget {
  const TaggedFilesView({super.key, required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<FileEntry>> files = ref.watch(_taggedProvider(tag.id));
    return Scaffold(
      appBar: FvAppBar(leading: const FvBackButton(), title: tag.name),
      body: files.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text(context.l10n.somethingWentWrong)),
        data: (List<FileEntry> entries) {
          if (entries.isEmpty) {
            return FvEmptyState(
              icon: Icons.label_outline,
              title: context.l10n.noTagsAssigned,
              message: context.l10n.tagsEmptyBody,
            );
          }
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 120 + context.padding.bottom),
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int i) => FvFileListTile(
              entry: entries[i],
              subtitle: entries[i].parentPath,
              onTap: () => openFileEntry(context, ref, entries[i], siblings: entries),
              onMore: () => showFileActionsSheet(context, ref, entries[i], siblings: entries),
            ),
          );
        },
      ),
    );
  }
}

final AutoDisposeFutureProviderFamily<List<FileEntry>, int> _taggedProvider =
    FutureProvider.autoDispose.family<List<FileEntry>, int>((Ref ref, int tagId) async {
  final List<String> paths = await ref.watch(collectionsRepositoryProvider).pathsWithTag(tagId);
  return _resolveFromRef(ref, paths);
});
