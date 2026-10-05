import 'package:filevault/features/browser/browser_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<BrowserViewModel, BrowserState> browserViewModelProvider =
    NotifierProvider<BrowserViewModel, BrowserState>(BrowserViewModel.new);

class BrowserViewModel extends Notifier<BrowserState> {
  @override
  BrowserState build() => const BrowserState();

  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == FileViewMode.list
          ? FileViewMode.grid
          : FileViewMode.list,
    );
  }

  void setSort(FileSortField field) {
    if (state.sortField == field) {
      state = state.copyWith(
        sortDirection: state.sortDirection == SortDirection.asc
            ? SortDirection.desc
            : SortDirection.asc,
      );
      return;
    }
    state = state.copyWith(sortField: field, sortDirection: SortDirection.asc);
  }

  void toggleHidden() {
    state = state.copyWith(showHidden: !state.showHidden);
  }
}
