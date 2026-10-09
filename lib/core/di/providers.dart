import 'package:filevault/data/database/app_database.dart';
import 'package:filevault/data/repositories/analyzer_repository_impl.dart';
import 'package:filevault/data/repositories/archive_repository_impl.dart';
import 'package:filevault/data/repositories/collections_repository_impl.dart';
import 'package:filevault/data/repositories/file_repository_impl.dart';
import 'package:filevault/data/repositories/index_repository_impl.dart';
import 'package:filevault/data/repositories/settings_repository_impl.dart';
import 'package:filevault/data/repositories/storage_repository_impl.dart';
import 'package:filevault/data/repositories/trash_repository_impl.dart';
import 'package:filevault/data/repositories/vault_repository_impl.dart';
import 'package:filevault/data/services/app_lock_service.dart';
import 'package:filevault/data/services/archive_service.dart';
import 'package:filevault/data/services/directory_cache.dart';
import 'package:filevault/data/services/file_system_service.dart';
import 'package:filevault/data/services/permission_data_source.dart';
import 'package:filevault/data/services/platform_channel_service.dart';
import 'package:filevault/data/services/thumbnail_service.dart';
import 'package:filevault/data/services/vault_crypto_service.dart';
import 'package:filevault/domain/repositories/analyzer_repository.dart';
import 'package:filevault/domain/repositories/archive_repository.dart';
import 'package:filevault/domain/repositories/collections_repository.dart';
import 'package:filevault/domain/repositories/file_repository.dart';
import 'package:filevault/domain/repositories/index_repository.dart';
import 'package:filevault/domain/repositories/settings_repository.dart';
import 'package:filevault/domain/repositories/storage_repository.dart';
import 'package:filevault/domain/repositories/trash_repository.dart';
import 'package:filevault/domain/repositories/vault_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composition root. The database is opened in `main()` and injected through
/// a ProviderScope override so every repository can be synchronous.
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>(
  (Ref ref) => throw UnimplementedError('appDatabaseProvider must be overridden in main()'),
);

// ----------------------------------------------------------------- services

final Provider<PlatformChannelService> platformChannelProvider =
    Provider<PlatformChannelService>((Ref ref) => PlatformChannelService());

/// Recent folder listings, shared by every browser screen.
final Provider<DirectoryCache> directoryCacheProvider =
    Provider<DirectoryCache>((Ref ref) => DirectoryCache());

final Provider<FileSystemService> fileSystemServiceProvider =
    Provider<FileSystemService>((Ref ref) => const FileSystemService());

final Provider<ArchiveService> archiveServiceProvider =
    Provider<ArchiveService>((Ref ref) => const ArchiveService());

final Provider<VaultCryptoService> vaultCryptoProvider =
    Provider<VaultCryptoService>((Ref ref) => const VaultCryptoService());

final Provider<ThumbnailService> thumbnailServiceProvider =
    Provider<ThumbnailService>((Ref ref) => ThumbnailService(ref.watch(platformChannelProvider)));

final Provider<AppLockService> appLockServiceProvider =
    Provider<AppLockService>((Ref ref) => AppLockService());

final Provider<PermissionDataSource> permissionDataSourceProvider =
    Provider<PermissionDataSource>((Ref ref) => PermissionDataSource());

// ------------------------------------------------------------- repositories

final Provider<FileRepository> fileRepositoryProvider = Provider<FileRepository>(
  (Ref ref) => FileRepositoryImpl(ref.watch(fileSystemServiceProvider)),
);

final Provider<StorageRepository> storageRepositoryProvider = Provider<StorageRepository>(
  (Ref ref) => StorageRepositoryImpl(
    ref.watch(platformChannelProvider),
    ref.watch(fileSystemServiceProvider),
  ),
);

final Provider<TrashRepository> trashRepositoryProvider = Provider<TrashRepository>(
  (Ref ref) => TrashRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(fileSystemServiceProvider),
    downloadsPath: ref.watch(storageRepositoryProvider).downloadsPath,
  ),
);

final Provider<CollectionsRepository> collectionsRepositoryProvider =
    Provider<CollectionsRepository>(
  (Ref ref) => CollectionsRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final Provider<IndexRepository> indexRepositoryProvider = Provider<IndexRepository>(
  (Ref ref) => IndexRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(storageRepositoryProvider),
  ),
);

final Provider<ArchiveRepository> archiveRepositoryProvider = Provider<ArchiveRepository>(
  (Ref ref) => ArchiveRepositoryImpl(ref.watch(archiveServiceProvider)),
);

final Provider<VaultRepository> vaultRepositoryProvider = Provider<VaultRepository>(
  (Ref ref) => VaultRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(fileSystemServiceProvider),
    ref.watch(vaultCryptoProvider),
  ),
);

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((Ref ref) => SettingsRepositoryImpl());

final Provider<PermissionRepository> permissionRepositoryProvider =
    Provider<PermissionRepository>(
  (Ref ref) => PermissionRepositoryImpl(
    ref.watch(permissionDataSourceProvider),
    ref.watch(platformChannelProvider),
  ),
);

final Provider<AnalyzerRepository> analyzerRepositoryProvider = Provider<AnalyzerRepository>(
  (Ref ref) => AnalyzerRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(fileSystemServiceProvider),
    ref.watch(indexRepositoryProvider),
    ref.watch(storageRepositoryProvider),
  ),
);
