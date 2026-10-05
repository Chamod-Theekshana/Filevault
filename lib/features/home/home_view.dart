import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/features/home/home_state.dart';
import 'package:filevault/features/home/home_viewmodel.dart';
import 'package:filevault/features/home/widgets/home_sections.dart';
import 'package:filevault/features/home/widgets/storage_overview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeState state = ref.watch(homeViewModelProvider);
    return Scaffold(
      appBar: FvAppBar(
        showBrand: true,
        actions: <Widget>[
          FvIconButton(
            icon: Icons.search,
            tooltip: context.l10n.searchAction,
            onPressed: () => context.go(AppRoutes.search),
          ),
          const SizedBox(width: 4),
          FvAvatarButton(onPressed: () => context.go(AppRoutes.settings)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          StorageOverviewCard(
            primary: state.primary,
            removable: state.removable,
            onCleanUp: () => context.push(AppRoutes.analyzer),
          ),
          const SizedBox(height: 24),
          CategoryGrid(categories: state.categories),
          const SizedBox(height: 24),
          _RecentsHeader(empty: state.recents.isEmpty),
          if (state.recents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                context.l10n.homeEmptyRecents,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 8),
          QuickAccessList(items: state.quickAccess),
        ],
      ),
    );
  }
}

class _RecentsHeader extends StatelessWidget {
  const _RecentsHeader({required this.empty});

  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(context.l10n.recentFiles, style: context.texts.headlineSmall),
        const Spacer(),
        if (!empty)
          TextButton(
            onPressed: () => context.push(AppRoutes.recents),
            child: Text(context.l10n.viewAll),
          ),
      ],
    );
  }
}
