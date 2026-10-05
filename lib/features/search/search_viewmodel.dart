import 'dart:async';

import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/utils/debouncer.dart';
import 'package:filevault/domain/models/search_models.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.filter = const SearchFilter(),
    this.hits = const <SearchHit>[],
    this.recent = const <String>[],
    this.searching = false,
    this.indexing = false,
    this.indexProgress = 0,
    this.indexStatus = const IndexStatus(),
    this.submitted = false,
  });

  final String query;
  final SearchFilter filter;
  final List<SearchHit> hits;
  final List<String> recent;
  final bool searching;
  final bool indexing;
  final double indexProgress;
  final IndexStatus indexStatus;

  /// True once a query has produced results (so the empty state differs from
  /// the initial screen).
  final bool submitted;

  SearchState copyWith({
    String? query,
    SearchFilter? filter,
    List<SearchHit>? hits,
    List<String>? recent,
    bool? searching,
    bool? indexing,
    double? indexProgress,
    IndexStatus? indexStatus,
    bool? submitted,
  }) {
    return SearchState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      hits: hits ?? this.hits,
      recent: recent ?? this.recent,
      searching: searching ?? this.searching,
      indexing: indexing ?? this.indexing,
      indexProgress: indexProgress ?? this.indexProgress,
      indexStatus: indexStatus ?? this.indexStatus,
      submitted: submitted ?? this.submitted,
    );
  }
}

final NotifierProvider<SearchViewModel, SearchState> searchProvider =
    NotifierProvider<SearchViewModel, SearchState>(SearchViewModel.new);

class SearchViewModel extends Notifier<SearchState> {
  final Debouncer _debounce = Debouncer(delay: const Duration(milliseconds: 220));
  int _generation = 0;

  @override
  SearchState build() {
    ref.onDispose(_debounce.dispose);
    Future<void>.microtask(_hydrate);
    return const SearchState();
  }

  Future<void> _hydrate() async {
    final List<String> recent = await ref.read(indexRepositoryProvider).recentSearches();
    final IndexStatus status = await ref.read(indexRepositoryProvider).status();
    state = state.copyWith(recent: recent, indexStatus: status);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    if (query.trim().isEmpty) {
      state = state.copyWith(hits: <SearchHit>[], submitted: false, searching: false);
      return;
    }
    state = state.copyWith(searching: true);
    _debounce(() => _run(query));
  }

  void setFilter(SearchFilter filter) {
    state = state.copyWith(filter: filter);
    if (state.query.trim().isNotEmpty) _run(state.query);
  }

  Future<void> submit() async {
    final String q = state.query.trim();
    if (q.isEmpty) return;
    await ref.read(indexRepositoryProvider).addRecentSearch(q);
    final List<String> recent = await ref.read(indexRepositoryProvider).recentSearches();
    state = state.copyWith(recent: recent);
    await _run(q);
  }

  Future<void> _run(String query) async {
    final int generation = ++_generation;
    final List<SearchHit> hits =
        await ref.read(indexRepositoryProvider).search(query, state.filter);
    if (generation != _generation) return;
    state = state.copyWith(hits: hits, searching: false, submitted: true);
  }

  Future<void> removeRecent(String query) async {
    await ref.read(indexRepositoryProvider).removeRecentSearch(query);
    state = state.copyWith(recent: await ref.read(indexRepositoryProvider).recentSearches());
  }

  Future<void> clearRecent() async {
    await ref.read(indexRepositoryProvider).clearRecentSearches();
    state = state.copyWith(recent: const <String>[]);
  }

  Future<void> rebuildIndex() async {
    if (state.indexing) return;
    state = state.copyWith(indexing: true, indexProgress: 0);
    await ref.read(indexRepositoryProvider).rebuild(
          includeHidden: ref.read(settingsProvider).showHiddenFiles,
          onProgress: (double f, String? _) {
            state = state.copyWith(indexProgress: f);
          },
        );
    final IndexStatus status = await ref.read(indexRepositoryProvider).status();
    state = state.copyWith(indexing: false, indexProgress: 1, indexStatus: status);
    if (state.query.trim().isNotEmpty) await _run(state.query);
  }
}
