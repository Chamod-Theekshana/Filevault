import 'package:filevault/features/search/search_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<SearchViewModel, SearchState> searchViewModelProvider =
    NotifierProvider<SearchViewModel, SearchState>(SearchViewModel.new);

class SearchViewModel extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void onQueryChanged(String value) {
    state = state.copyWith(query: value);
  }
}
