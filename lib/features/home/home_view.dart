import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:filevault/domain/models/vault_item.dart';
import 'package:filevault/features/home/home_viewmodel.dart';
import 'package:filevault/features/home/widgets/home_sections.dart';
import 'package:filevault/features/home/widgets/storage_overview_card.dart';
import 'package:filevault/features/viewer/open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home: storage summary, categories, recents, quick access, secure folder.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeState state = ref.watch(homeProvider);
    final HomeViewModel vm = ref.read(homeProvider.notifier);
    return Scaffold(
      appBar: FvAppBar(
        showBrand: true,
        actions: <Widget>[
          FvIconButton(
            icon: Icons.search,
            tooltip: context.l10n.search,
            onPressed: () => context.go(AppRoutes.search),
          ),
          FvAvatarButton(onPressed: () => context.go(AppRoutes.settings)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          padding: EdgeInsets.only(bottom: 140 + context.padding.bottom),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: StorageOverviewCard(
                primary: state.primary,
                removable: state.removable,
                onCleanUp: () => context.push(AppRoutes.analyzer),
                onOpenVolume: (StorageVolume v) =>
                    context.push(AppRoutes.withPath(AppRoutes.browse, v.path)),
              ),
            ),
            FvSectionHeader(
              title: context.l10n.categories,
              uppercase: false,
              trailing: Text(
                context.l10n.categoriesCount(FileCategory.homeTiles.length),
                style: context.texts.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryGrid(
                categories: state.categories,
                trashCount: state.trashCount,
                trashBytes: state.trashBytes,
                indexed: state.indexed,
                onTap: (FileCategory c) => _openCategory(context, c),
              ),
            ),
            if (!state.indexed && !state.loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: FvInfoBanner(
                  icon: Icons.radar,
                  title: context.l10n.indexEmptyTitle,
                  subtitle: context.l10n.indexEmptyBody,
                  trailing: FvTonalButton(label: context.l10n.scan, onPressed: vm.buildIndex),
                ),
              ),
            const SizedBox(height: 8),
            FvSectionHeader(
              title: context.l10n.recentFiles,
              uppercase: false,
              trailing: state.recents.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () => context.push(AppRoutes.recents),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(context.l10n.viewAll),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
            ),
            if (state.recents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.l10n.noRecentFiles,
                  style: context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              )
            else
              RecentFilesRow(
                files: state.recents,
                onOpen: (FileEntry e) => openFileEntry(context, ref, e),
              ),
            FvSectionHeader(title: context.l10n.secureFolder, uppercase: false),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SecureFolderCard(
                itemCount: state.vaultCount,
                configured: state.vaultStatus != VaultStatus.notConfigured,
                onTap: () => context.push(AppRoutes.vault),
              ),
            ),
            FvSectionHeader(
              title: context.l10n.quickAccess,
              uppercase: false,
              trailing: PopupMenuButton<String>(
                tooltip: context.l10n.quickAccessMore,
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (String value) {
                  switch (value) {
                    case 'favorites':
                      context.push(AppRoutes.favorites);
                    case 'tags':
                      context.push(AppRoutes.tags);
                    case 'operations':
                      context.push(AppRoutes.operations);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'favorites', child: Text(context.l10n.favorites)),
                  PopupMenuItem<String>(value: 'tags', child: Text(context.l10n.tags)),
                  PopupMenuItem<String>(value: 'operations', child: Text(context.l10n.operationsHistory)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuickAccessList(
                items: state.quickAccess,
                onOpen: (QuickAccessEntry e) =>
                    context.push(AppRoutes.withPath(AppRoutes.browse, e.path)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, FileCategory category) {
    if (category == FileCategory.trash) {
      context.push(AppRoutes.trash);
      return;
    }
    context.push(Uri(
      path: AppRoutes.category,
      queryParameters: <String, String>{'category': category.name},
    ).toString());
  }
}
