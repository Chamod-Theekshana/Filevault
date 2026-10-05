import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/app_colors.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/features/browser/browser_state.dart';
import 'package:filevault/features/browser/browser_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrowserView extends ConsumerWidget {
  const BrowserView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrowserState state = ref.watch(browserViewModelProvider);
    final BrowserViewModel vm = ref.read(browserViewModelProvider.notifier);
    return Scaffold(
      appBar: FvAppBar(
        showBrand: true,
        actions: <Widget>[
          FvIconButton(
            icon: state.viewMode == FileViewMode.list
                ? Icons.grid_view
                : Icons.view_list,
            tooltip: state.viewMode == FileViewMode.list
                ? context.l10n.gridView
                : context.l10n.listView,
            onPressed: vm.toggleViewMode,
          ),
          FvIconButton(
            icon: Icons.sort,
            tooltip: context.l10n.defaultSort,
            onPressed: () => _openSort(context, vm, state),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (int i = 0; i < state.breadcrumbs.length; i++) ...<Widget>[
                  if (i > 0)
                    Icon(Icons.chevron_right, size: 14, color: context.colors.outline),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: i == state.breadcrumbs.length - 1
                        ? BoxDecoration(
                            color: context.isDark
                                ? AppColors.darkPrimaryContainer
                                : AppColors.lightPrimaryFixed.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(999),
                          )
                        : null,
                    child: Text(
                      state.breadcrumbs[i],
                      style: context.texts.labelSmall?.copyWith(
                        color: i == state.breadcrumbs.length - 1
                            ? context.colors.primary
                            : context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: FvEmptyState(
              icon: Icons.folder_open,
              title: context.l10n.browserEmptyTitle,
              message: context.l10n.browserEmptyBody,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSort(
    BuildContext context,
    BrowserViewModel vm,
    BrowserState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final FileSortField field in FileSortField.values)
                ListTile(
                  leading: Icon(
                    field == FileSortField.name
                        ? Icons.sort_by_alpha
                        : field == FileSortField.size
                            ? Icons.data_usage
                            : field == FileSortField.date
                                ? Icons.schedule
                                : Icons.category_outlined,
                  ),
                  title: Text(_sortLabel(context, field)),
                  trailing: state.sortField == field ? const Icon(Icons.check_circle) : null,
                  onTap: () {
                    vm.setSort(field);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _sortLabel(BuildContext context, FileSortField field) {
    return switch (field) {
      FileSortField.name => context.l10n.sortName,
      FileSortField.size => context.l10n.sortSize,
      FileSortField.date => context.l10n.sortDate,
      FileSortField.type => context.l10n.sortType,
    };
  }
}
