import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_thumbnail.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/search_models.dart';
import 'package:filevault/features/browser/widgets/file_actions_sheet.dart';
import 'package:filevault/features/home/widgets/home_sections.dart';
import 'package:filevault/features/search/search_viewmodel.dart';
import 'package:filevault/features/viewer/open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Global search across the index with type, size and date filters.
class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SearchState state = ref.watch(searchProvider);
    final SearchViewModel vm = ref.read(searchProvider.notifier);
    return Scaffold(
      appBar: FvAppBar(
        showBrand: true,
        actions: <Widget>[
          FvAvatarButton(onPressed: () => context.go(AppRoutes.settings)),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              onChanged: vm.setQuery,
              onSubmitted: (_) => vm.submit(),
              decoration: InputDecoration(
                hintText: context.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          vm.setQuery('');
                        },
                      ),
              ),
            ),
          ),
          _FilterRow(state: state, onChanged: vm.setFilter),
          if (state.indexing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: <Widget>[
                  FvLoadingBar(value: state.indexProgress == 0 ? null : state.indexProgress),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Text(context.l10n.scanning, style: context.texts.bodySmall),
                      const Spacer(),
                      Text(
                        '${(state.indexProgress * 100).round()}%',
                        style: context.texts.bodySmall?.copyWith(color: context.colors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(child: _body(state, vm)),
        ],
      ),
    );
  }

  Widget _body(SearchState state, SearchViewModel vm) {
    final List<Widget> children = <Widget>[];
    if (state.query.isEmpty && state.recent.isNotEmpty) {
      children.add(_RecentSearches(
        items: state.recent,
        onTap: (String q) {
          _controller.text = q;
          _controller.selection = TextSelection.collapsed(offset: q.length);
          vm.setQuery(q);
        },
        onRemove: vm.removeRecent,
        onClear: vm.clearRecent,
      ));
    }
    if (state.query.isNotEmpty) {
      children.add(
        FvSectionHeader(
          title: context.l10n.resultsFor(state.query),
          uppercase: false,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          trailing: state.searching
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : FvCountBadge(context.l10n.found(state.hits.length)),
        ),
      );
      if (!state.searching && state.hits.isEmpty && state.submitted) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: FvEmptyState(
            icon: Icons.search_off,
            title: context.l10n.noResultsTitle,
            message: context.l10n.noResultsBody,
          ),
        ));
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FvCard(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < state.hits.length; i++)
                    _ResultRow(
                      hit: state.hits[i],
                      last: i == state.hits.length - 1,
                      onTap: () => openFileEntry(
                        context,
                        ref,
                        state.hits[i].entry,
                        siblings: state.hits.map((SearchHit h) => h.entry).toList(),
                      ),
                      onMore: () => showFileActionsSheet(context, ref, state.hits[i].entry),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }
    children.add(Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: FvInfoBanner(
        icon: Icons.radar,
        title: context.l10n.deepScan,
        subtitle: state.indexStatus.lastIndexedAt == null
            ? context.l10n.deepScanBody
            : '${context.l10n.indexedFiles(state.indexStatus.indexedFiles)} • ${DateFormatter.ago(state.indexStatus.lastIndexedAt!)}',
        trailing: FvFilledButton(
          label: context.l10n.scan,
          expand: false,
          busy: state.indexing,
          onPressed: vm.rebuildIndex,
        ),
      ),
    ));
    children.add(SizedBox(height: 140 + context.padding.bottom));
    return ListView(children: children);
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.state, required this.onChanged});

  final SearchState state;
  final ValueChanged<SearchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final SearchFilter f = state.filter;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          FvChip(
            label: context.l10n.all,
            icon: f.category == null ? Icons.check : null,
            selected: f.category == null,
            onTap: () => onChanged(f.copyWith(clearCategory: true)),
          ),
          const SizedBox(width: 8),
          for (final FileCategory c in FileCategory.browsable) ...<Widget>[
            FvChip(
              label: categoryLabel(context.l10n, c),
              selected: f.category == c,
              onTap: () => onChanged(f.category == c ? f.copyWith(clearCategory: true) : f.copyWith(category: c)),
            ),
            const SizedBox(width: 8),
          ],
          PopupMenuButton<SizeBucket>(
            onSelected: (SizeBucket b) => onChanged(f.copyWith(size: b)),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SizeBucket>>[
              PopupMenuItem<SizeBucket>(value: SizeBucket.any, child: Text(context.l10n.anySize)),
              PopupMenuItem<SizeBucket>(value: SizeBucket.small, child: Text(context.l10n.sizeSmall)),
              PopupMenuItem<SizeBucket>(value: SizeBucket.medium, child: Text(context.l10n.sizeMedium)),
              PopupMenuItem<SizeBucket>(value: SizeBucket.large, child: Text(context.l10n.sizeLarge)),
            ],
            child: Center(
              child: FvChip(
                label: switch (f.size) {
                  SizeBucket.any => context.l10n.sizeRange,
                  SizeBucket.small => context.l10n.sizeSmall,
                  SizeBucket.medium => context.l10n.sizeMedium,
                  SizeBucket.large => context.l10n.sizeLarge,
                },
                trailingIcon: Icons.expand_more,
                selected: f.size != SizeBucket.any,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<DateBucket>(
            onSelected: (DateBucket b) => onChanged(f.copyWith(date: b)),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<DateBucket>>[
              PopupMenuItem<DateBucket>(value: DateBucket.any, child: Text(context.l10n.anyDate)),
              PopupMenuItem<DateBucket>(value: DateBucket.week, child: Text(context.l10n.last7Days)),
              PopupMenuItem<DateBucket>(value: DateBucket.month, child: Text(context.l10n.last30Days)),
              PopupMenuItem<DateBucket>(value: DateBucket.year, child: Text(context.l10n.thisYear)),
            ],
            child: Center(
              child: FvChip(
                label: switch (f.date) {
                  DateBucket.any => context.l10n.dateRange,
                  DateBucket.week => context.l10n.last7Days,
                  DateBucket.month => context.l10n.last30Days,
                  DateBucket.year => context.l10n.thisYear,
                },
                trailingIcon: Icons.expand_more,
                selected: f.date != DateBucket.any,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.items,
    required this.onTap,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> items;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: FvCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(context.l10n.recentSearches, style: context.texts.headlineSmall?.copyWith(fontSize: 16)),
                const Spacer(),
                TextButton(onPressed: onClear, child: Text(context.l10n.clearAll)),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String q in items)
                  InputChip(
                    avatar: const Icon(Icons.history, size: 18),
                    label: Text(q),
                    onPressed: () => onTap(q),
                    onDeleted: () => onRemove(q),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.hit,
    required this.last,
    required this.onTap,
    required this.onMore,
  });

  final SearchHit hit;
  final bool last;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final String name = hit.entry.name;
    final bool hasMatch = hit.matchEnd > hit.matchStart;
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: <Widget>[
              FvThumbnail(entry: hit.entry, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                      TextSpan(
                        style: context.texts.titleSmall,
                        children: hasMatch
                            ? <InlineSpan>[
                                TextSpan(text: name.substring(0, hit.matchStart)),
                                TextSpan(
                                  text: name.substring(hit.matchStart, hit.matchEnd),
                                  style: TextStyle(
                                    backgroundColor: context.isDark
                                        ? context.colors.primaryContainer
                                        : context.colors.primaryFixed,
                                    color: context.isDark ? context.colors.onPrimaryContainer : context.colors.primary,
                                  ),
                                ),
                                TextSpan(text: name.substring(hit.matchEnd)),
                              ]
                            : <InlineSpan>[TextSpan(text: name)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hit.entry.parentPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    FileSizeFormatter.format(hit.entry.size),
                    style: context.texts.labelMedium?.copyWith(
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    DateFormatter.short(hit.entry.modified),
                    style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(icon: const Icon(Icons.more_vert), onPressed: onMore),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
