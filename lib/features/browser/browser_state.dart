import 'package:freezed_annotation/freezed_annotation.dart';

part 'browser_state.freezed.dart';

enum FileViewMode { list, grid }

enum FileSortField { name, size, date, type }

enum SortDirection { asc, desc }

@freezed
class BrowserState with _$BrowserState {
  const factory BrowserState({
    @Default(<String>['Internal storage']) List<String> breadcrumbs,
    @Default(FileViewMode.list) FileViewMode viewMode,
    @Default(FileSortField.name) FileSortField sortField,
    @Default(SortDirection.asc) SortDirection sortDirection,
    @Default(true) bool foldersFirst,
    @Default(false) bool showHidden,
    @Default(<String>{}) Set<String> selectedPaths,
    @Default(false) bool isLoading,
  }) = _BrowserState;
}
