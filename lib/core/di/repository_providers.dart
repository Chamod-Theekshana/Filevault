import 'package:filevault/data/repositories/permission_repository_impl.dart';
import 'package:filevault/data/repositories/settings_repository_impl.dart';
import 'package:filevault/data/services/storage_permission_data_source.dart';
import 'package:filevault/domain/repositories/permission_repository.dart';
import 'package:filevault/domain/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<StoragePermissionDataSource> storagePermissionDataSourceProvider =
    Provider<StoragePermissionDataSource>(
  (Ref ref) => StoragePermissionDataSource(),
);

final Provider<PermissionRepository> permissionRepositoryProvider =
    Provider<PermissionRepository>(
  (Ref ref) => PermissionRepositoryImpl(ref.watch(storagePermissionDataSourceProvider)),
);

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
  (Ref ref) => SettingsRepositoryImpl(),
);
