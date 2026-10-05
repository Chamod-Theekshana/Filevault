import 'package:filevault/core/di/providers.dart';
import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/collection_items.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/storage_volume.dart';
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
  @override
  HomeState build() {
    // Refresh whenever a file operation finishes.
    ref.listen(operationFinishedProvider, (_, _) => refresh());
    Future<void>.microtask(refresh);
    return const HomeState();
  }

  Future<void> refresh() async {
    final List<StorageVolume> volumes = await ref.read(storageRepositoryProvider).volumes();
    final List<QuickAccessEntry> quick = await ref.read(storageRepositoryProvider).quickAccess();
    final bool empty = await ref.read(indexRepositoryProvider).isEmpty;
    final List<CategorySummary> categories =
        empty ? const <CategorySummary>[] : await ref.read(indexRepositoryProvider).categorySummaries();
    final List<RecentItem> recentRows = await ref.read(collectionsRepositoryProvider).recents(limit: 12);
    final List<FileEntry> recents = <FileEntry>[];
    for (final RecentItem r in recentRows) {
      final FileEntry? e = (await ref.read(fileRepositoryProvider).stat(r.path)).valueOrNull;
      if (e != null) recents.add(e);
    }
    final int trashCount = (await ref.read(trashRepositoryProvider).items()).length;
    final int trashBytes = await ref.read(trashRepositoryProvider).totalBytes();
    final bool vaultConfigured = await ref.read(vaultRepositoryProvider).isConfigured();
    final int vaultCount = vaultConfigured
        ? (await ref.read(vaultRepositoryProvider).items()).length
        : 0;
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
  }

  /// Builds the search index, which also fills the category tiles.
  Future<void> buildIndex() async {
    final bool showHidden = ref.read(settingsProvider).showHiddenFiles;
    await ref.read(indexRepositoryProvider).rebuild(includeHidden: showHidden);
    await refresh();
  }
}
