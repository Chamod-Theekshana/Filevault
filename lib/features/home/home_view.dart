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

/// Home: free space at a glance, categories, recent files, the Secure Folder
/// and the folders people open every day.
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          padding: EdgeInsets.only(bottom: 140 + context.padding.bottom),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: StorageOverviewCard(
                primary: state.primary,
                removable: state.removable,
                categories: state.categories,
                indexed: state.indexed,
                onCleanUp: () => context.push(AppRoutes.analyzer),
                onAnalyze: () => context.push(AppRoutes.analyzer),
                onOpenVolume: (StorageVolume v) =>
                    context.push(AppRoutes.withPath(AppRoutes.browse, v.path)),
              ),
            ),
            FvSectionHeader(
              title: context.l10n.categories,
              uppercase: false,
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 4),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: FvInfoBanner(
                  icon: Icons.manage_search,
                  title: context.l10n.indexEmptyTitle,
                  subtitle: context.l10n.indexEmptyBody,
                  trailing: FvTonalButton(label: context.l10n.scan, onPressed: vm.buildIndex),
                ),
              ),
            FvSectionHeader(
              title: context.l10n.recentFiles,
              uppercase: false,
              padding: const EdgeInsets.fromLTRB(20, 22, 8, 8),
              trailing: state.recents.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () => context.push(AppRoutes.recents),
                      child: Text(context.l10n.viewAll),
                    ),
            ),
            if (state.recents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: SecureFolderCard(
                itemCount: state.vaultCount,
                configured: state.vaultStatus != VaultStatus.notConfigured,
                unlocked: state.vaultStatus == VaultStatus.unlocked,
                onTap: () => context.push(AppRoutes.vault),
              ),
            ),
            if (state.quickAccess.isNotEmpty) ...<Widget>[
              FvSectionHeader(
                title: context.l10n.quickAccess,
                uppercase: false,
                padding: const EdgeInsets.fromLTRB(20, 24, 16, 8),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ToolShortcuts(
                items: <(IconData, String, VoidCallback)>[
                  (Icons.star_outline_rounded, context.l10n.favorites, () => context.push(AppRoutes.favorites)),
                  (Icons.sell_outlined, context.l10n.tags, () => context.push(AppRoutes.tags)),
                  (Icons.delete_outline, context.l10n.trash, () => context.push(AppRoutes.trash)),
                  (Icons.history, context.l10n.activity, () => context.push(AppRoutes.operations)),
                ],
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
