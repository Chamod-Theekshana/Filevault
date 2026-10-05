import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/features/search/search_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchView extends ConsumerWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(searchViewModelProvider);
    return Scaffold(
      appBar: FvAppBar(
        title: Text(context.l10n.navSearch),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              onChanged: ref.read(searchViewModelProvider.notifier).onQueryChanged,
              decoration: InputDecoration(
                hintText: context.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FvEmptyState(
                icon: Icons.search,
                title: context.l10n.searchEmptyTitle,
                message: context.l10n.searchEmptyBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
