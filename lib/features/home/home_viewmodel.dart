import 'dart:async';

import 'package:filevault/core/di/providers.dart';
import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/collection_items.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:filevault/domain/models/trash_item.dart';
import 'package:filevault/domain/models/vault_item.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeState {
  const HomeState({
    this.volumes = const <StorageVolume>[],
    this.categories = const <CategorySummary>[],
    this.recents = const <FileEntry>[],
    this.quickAccess = const <QuickAccessEntry>[],
    this.trashCount = 0,
    this.trashBytes = 0,
    this.vaultCount = 0,
    this.vaultStatus = VaultStatus.notConfigured,
    this.indexed = false,
    this.loading = true,
  });

  final List<StorageVolume> volumes;
  final List<CategorySummary> categories;
  final List<FileEntry> recents;
  final List<QuickAccessEntry> quickAccess;
  final int trashCount;
  final int trashBytes;
  final int vaultCount;
  final VaultStatus vaultStatus;

  /// False until the search index has been built at least once; the home
  /// screen then shows a "scan" hint instead of empty category counts.
  final bool indexed;
  final bool loading;

  StorageVolume get primary =>
      volumes.isEmpty ? StorageVolume.fallback : volumes.firstWhere((StorageVolume v) => v.isPrimary, orElse: () => volumes.first);

  StorageVolume? get removable {
    for (final StorageVolume v in volumes) {
      if (!v.isPrimary) return v;
    }
    return null;
  }

  CategorySummary summary(FileCategory c) => categories.firstWhere(
        (CategorySummary s) => s.category == c,
        orElse: () => CategorySummary.empty(c),
      );

  HomeState copyWith({
    List<StorageVolume>? volumes,
    List<CategorySummary>? categories,
    List<FileEntry>? recents,
    List<QuickAccessEntry>? quickAccess,
    int? trashCount,
    int? trashBytes,
    int? vaultCount,
    VaultStatus? vaultStatus,
    bool? indexed,
    bool? loading,
  }) {
    return HomeState(
      volumes: volumes ?? this.volumes,
      categories: categories ?? this.categories,
      recents: recents ?? this.recents,
      quickAccess: quickAccess ?? this.quickAccess,
      trashCount: trashCount ?? this.trashCount,
      trashBytes: trashBytes ?? this.trashBytes,
      vaultCount: vaultCount ?? this.vaultCount,
      vaultStatus: vaultStatus ?? this.vaultStatus,
      indexed: indexed ?? this.indexed,
      loading: loading ?? this.loading,
    );
  }
}

final NotifierProvider<HomeViewModel, HomeState> homeProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeState> {
  Completer<void> _firstLoad = Completer<void>();

  /// Completes once the first full refresh has finished. The splash screen
  /// waits for this so Home never appears half-empty.
  Future<void> get firstLoad => _firstLoad.future;

  @override
  HomeState build() {
    _firstLoad = Completer<void>();
    // Refresh whenever a file operation finishes.
    ref.listen(operationFinishedProvider, (_, _) => refresh());
    Future<void>.microtask(refresh);
    return const HomeState();
  }

  static Future<T> _safe<T>(Future<T> future, T fallback) =>
      future.catchError((Object _) => fallback);

  Future<void> refresh() async {
    try {
      // Everything below is independent – start it all at once.
      final Future<List<StorageVolume>> volumesF =
          _safe(ref.read(storageRepositoryProvider).volumes(), const <StorageVolume>[]);
      final Future<List<QuickAccessEntry>> quickF =
          _safe(ref.read(storageRepositoryProvider).quickAccess(), const <QuickAccessEntry>[]);
      final Future<bool> emptyF = _safe(ref.read(indexRepositoryProvider).isEmpty, true);
      final Future<List<RecentItem>> recentF =
          _safe(ref.read(collectionsRepositoryProvider).recents(limit: 12), const <RecentItem>[]);
      final Future<int> trashCountF = _safe(
        ref.read(trashRepositoryProvider).items().then((List<TrashItem> l) => l.length),
        0,
      );
      final Future<int> trashBytesF = _safe(ref.read(trashRepositoryProvider).totalBytes(), 0);
      final Future<bool> vaultConfiguredF =
          _safe(ref.read(vaultRepositoryProvider).isConfigured(), false);
      final Future<int> vaultCountF = _safe(ref.read(vaultRepositoryProvider).itemCount(), 0);

      final bool empty = await emptyF;
      final Future<List<CategorySummary>> categoriesF = empty
          ? Future<List<CategorySummary>>.value(const <CategorySummary>[])
          : _safe(ref.read(indexRepositoryProvider).categorySummaries(), const <CategorySummary>[]);

      final List<RecentItem> recentRows = await recentF;
      final List<FileEntry?> stats = await Future.wait<FileEntry?>(<Future<FileEntry?>>[
        for (final RecentItem r in recentRows)
          _safe(
            ref.read(fileRepositoryProvider).stat(r.path).then((res) => res.valueOrNull),
            null,
          ),
      ]);
      final List<FileEntry> recents = <FileEntry>[
        for (final FileEntry? e in stats)
          if (e != null) e,
      ];

      final List<StorageVolume> volumes = await volumesF;
      final List<QuickAccessEntry> quick = await quickF;
      final List<CategorySummary> categories = await categoriesF;
      final int trashCount = await trashCountF;
      final int trashBytes = await trashBytesF;
      final bool vaultConfigured = await vaultConfiguredF;
      final int vaultCount = vaultConfigured ? await vaultCountF : 0;
      state = state.copyWith(
        volumes: volumes,
        quickAccess: quick,
        categories: categories,
        recents: recents,
        trashCount: trashCount,
        trashBytes: trashBytes,
        vaultCount: vaultCount,
        vaultStatus: !vaultConfigured
            ? VaultStatus.notConfigured
            : ref.read(vaultRepositoryProvider).isUnlocked
                ? VaultStatus.unlocked
                : VaultStatus.locked,
        indexed: !empty,
        loading: false,
      );
    } finally {
      if (!_firstLoad.isCompleted) _firstLoad.complete();
    }
  }

  /// Builds the search index, which also fills the category tiles.
  Future<void> buildIndex() async {
    final bool showHidden = ref.read(settingsProvider).showHiddenFiles;
    await ref.read(indexRepositoryProvider).rebuild(includeHidden: showHidden);
    await refresh();
  }
}
