import 'dart:async';

import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class BrowserState {
  const BrowserState({
    required this.path,
    this.entries = const <FileEntry>[],
    this.selected = const <String>{},
    this.loading = true,
    this.failure,
    this.restricted = false,
    this.volume,
    this.freeBytes = 0,
    this.sort = const SortSpec(),
    this.viewMode = ViewMode.list,
    this.showHidden = false,
    this.selecting = false,
    this.query = '',
  });

  final String path;
  final List<FileEntry> entries;
  final Set<String> selected;
  final bool loading;
  final Failure? failure;
  final bool restricted;
  final StorageVolume? volume;
  final int freeBytes;
  final SortSpec sort;
  final ViewMode viewMode;
  final bool showHidden;
  final bool selecting;

  /// In-folder filter typed by the user.
  final String query;

  List<FileEntry> get visible {
    if (query.isEmpty) return entries;
    final String q = query.toLowerCase();
    return entries.where((FileEntry e) => e.name.toLowerCase().contains(q)).toList(growable: false);
  }

  List<FileEntry> get folders =>
      visible.where((FileEntry e) => e.isDirectory).toList(growable: false);

  List<FileEntry> get files =>
      visible.where((FileEntry e) => !e.isDirectory).toList(growable: false);

  List<FileEntry> get selectedEntries =>
      entries.where((FileEntry e) => selected.contains(e.path)).toList(growable: false);

  int get selectedBytes =>
      selectedEntries.fold(0, (int a, FileEntry e) => a + e.size);

  int get selectedFolderCount =>
      selectedEntries.where((FileEntry e) => e.isDirectory).length;

  int get selectedFileCount =>
      selectedEntries.where((FileEntry e) => !e.isDirectory).length;

  int get totalCount => entries.length;

  bool get allSelected => entries.isNotEmpty && selected.length == entries.length;

  BrowserState copyWith({
    String? path,
    List<FileEntry>? entries,
    Set<String>? selected,
    bool? loading,
    Failure? failure,
    bool clearFailure = false,
    bool? restricted,
    StorageVolume? volume,
    int? freeBytes,
    SortSpec? sort,
    ViewMode? viewMode,
    bool? showHidden,
    bool? selecting,
    String? query,
  }) {
    return BrowserState(
      path: path ?? this.path,
      entries: entries ?? this.entries,
      selected: selected ?? this.selected,
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
      restricted: restricted ?? this.restricted,
      volume: volume ?? this.volume,
      freeBytes: freeBytes ?? this.freeBytes,
      sort: sort ?? this.sort,
      viewMode: viewMode ?? this.viewMode,
      showHidden: showHidden ?? this.showHidden,
      selecting: selecting ?? this.selecting,
      query: query ?? this.query,
    );
  }
}

/// One browser instance per folder path, kept alive while the screen is up.
final AutoDisposeNotifierProviderFamily<BrowserViewModel, BrowserState, String>
    browserProvider =
    NotifierProvider.autoDispose.family<BrowserViewModel, BrowserState, String>(
  BrowserViewModel.new,
);

class BrowserViewModel extends AutoDisposeFamilyNotifier<BrowserState, String> {
  StreamSubscription<List<FileEntry>>? _sub;
  int _generation = 0;
  bool _disposed = false;

  @override
  BrowserState build(String arg) {
    final AppSettings settings = ref.watch(settingsProvider);
    ref.listen(operationFinishedProvider, (_, _) => refresh());
    ref.onDispose(() {
      _disposed = true;
      _sub?.cancel();
    });
    Future<void>.microtask(load);
    return BrowserState(
      path: arg,
      sort: settings.defaultSort,
      viewMode: settings.defaultViewMode,
      showHidden: settings.showHiddenFiles,
    );
  }

  bool _stale(int generation) => _disposed || generation != _generation;

  Future<void> load() async {
    if (_disposed) return;
    final int generation = ++_generation;
    await _sub?.cancel();
    if (_stale(generation)) return;
    state = state.copyWith(loading: true, clearFailure: true, entries: <FileEntry>[]);

    if (ref.read(fileRepositoryProvider).isRestricted(state.path)) {
      state = state.copyWith(loading: false, restricted: true);
      return;
    }

    final List<StorageVolume> volumes = await ref.read(storageRepositoryProvider).volumes();
    StorageVolume? volume;
    for (final StorageVolume v in volumes) {
      if (FileUtils.isWithin(v.path, state.path)) volume = v;
    }
    if (_stale(generation)) return;
    state = state.copyWith(volume: volume, freeBytes: volume?.freeBytes ?? 0);

    final List<FileEntry> collected = <FileEntry>[];
    _sub = ref
        .read(fileRepositoryProvider)
        .listDirectory(state.path, showHidden: state.showHidden)
        .listen(
      (List<FileEntry> batch) {
        if (_stale(generation)) return;
        collected.addAll(batch);
        state = state.copyWith(entries: state.sort.apply(collected), loading: true);
      },
      onError: (Object error) {
        if (_stale(generation)) return;
        state = state.copyWith(loading: false, failure: Failure.fromException(error));
      },
      onDone: () async {
        if (_stale(generation)) return;
        state = state.copyWith(entries: state.sort.apply(collected), loading: false);
        await _countFolderChildren(generation, collected);
      },
      cancelOnError: true,
    );
  }

  /// Fills in "24 items" for folders, a few at a time so the list stays smooth.
  Future<void> _countFolderChildren(int generation, List<FileEntry> entries) async {
    final List<FileEntry> folders =
        entries.where((FileEntry e) => e.isDirectory && e.childCount == null).toList();
    if (folders.isEmpty) return;
    final Map<String, int> counts = <String, int>{};
    for (int i = 0; i < folders.length; i++) {
      if (_stale(generation)) return;
      final Result<int> r = await ref.read(fileRepositoryProvider).countChildren(folders[i].path);
      counts[folders[i].path] = r.valueOrNull ?? 0;
      final bool lastOfBatch = (i + 1) % 12 == 0 || i == folders.length - 1;
      if (!lastOfBatch) continue;
      if (_stale(generation)) return;
      state = state.copyWith(
        entries: <FileEntry>[
          for (final FileEntry e in state.entries)
            counts.containsKey(e.path) ? e.copyWith(childCount: counts[e.path]) : e,
        ],
      );
    }
  }

  Future<void> refresh() => load();

  // ------------------------------------------------------------ view ops

  void setSort(SortSpec sort) {
    state = state.copyWith(sort: sort, entries: sort.apply(state.entries));
  }

  void toggleSortField(SortField field) {
    final SortSpec next = state.sort.field == field
        ? state.sort.copyWith(
            direction: state.sort.direction == SortDirection.asc
                ? SortDirection.desc
                : SortDirection.asc,
          )
        : state.sort.copyWith(field: field, direction: SortDirection.asc);
    setSort(next);
  }

  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list,
    );
  }

  Future<void> toggleHidden() async {
    state = state.copyWith(showHidden: !state.showHidden);
    await load();
  }

  void setQuery(String query) => state = state.copyWith(query: query);

  // ------------------------------------------------------------ selection

  void startSelection(String path) {
    state = state.copyWith(selecting: true, selected: <String>{path});
  }

  void toggle(String path) {
    final Set<String> next = Set<String>.of(state.selected);
    if (!next.remove(path)) next.add(path);
    state = state.copyWith(selected: next, selecting: next.isNotEmpty);
  }

  void selectAll() {
    state = state.copyWith(
      selected: state.visible.map((FileEntry e) => e.path).toSet(),
      selecting: true,
    );
  }

  void invertSelection() {
    final Set<String> next = <String>{
      for (final FileEntry e in state.visible)
        if (!state.selected.contains(e.path)) e.path,
    };
    state = state.copyWith(selected: next, selecting: next.isNotEmpty);
  }

  void clearSelection() =>
      state = state.copyWith(selected: <String>{}, selecting: false);

  // ------------------------------------------------------------- file ops

  Future<Result<FileEntry>> createFolder(String name) async {
    final Result<FileEntry> r =
        await ref.read(fileRepositoryProvider).createFolder(state.path, name);
    if (r.isSuccess) await refresh();
    return r;
  }

  Future<Result<FileEntry>> createFile(String name) async {
    final Result<FileEntry> r =
        await ref.read(fileRepositoryProvider).createFile(state.path, name);
    if (r.isSuccess) await refresh();
    return r;
  }

  Future<Result<FileEntry>> rename(FileEntry entry, String newName) async {
    final Result<FileEntry> r =
        await ref.read(fileRepositoryProvider).rename(entry.path, newName);
    final FileEntry? renamed = r.valueOrNull;
    if (_disposed) return r;
    if (renamed != null) {
      await ref.read(collectionsRepositoryProvider).pathMoved(entry.path, renamed.path);
      await ref.read(indexRepositoryProvider).movePath(entry.path, renamed.path);
      await refresh();
    }
    return r;
  }

  Future<Result<FileEntry>> duplicate(FileEntry entry) async {
    final Result<FileEntry> r = await ref.read(fileRepositoryProvider).duplicate(entry.path);
    if (r.isSuccess) await refresh();
    return r;
  }

  bool nameExists(String name) => state.entries.any((FileEntry e) => e.name == name);

  /// Suggested archive name for the current selection.
  String suggestedArchiveName() {
    final List<FileEntry> selected = state.selectedEntries;
    final String base = selected.length == 1
        ? selected.first.stem
        : p.basename(state.path).isEmpty
            ? AppConstants.appName
            : p.basename(state.path);
    return base;
  }
}
