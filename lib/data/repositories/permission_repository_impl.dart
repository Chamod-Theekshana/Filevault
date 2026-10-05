import 'package:filevault/data/services/storage_permission_data_source.dart';
import 'package:filevault/domain/models/storage_permission_status.dart';
import 'package:filevault/domain/repositories/permission_repository.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  PermissionRepositoryImpl(this._dataSource);

  final StoragePermissionDataSource _dataSource;

  @override
  Future<StoragePermissionStatus> currentStatus() => _dataSource.readStatus();

  @override
  Future<StoragePermissionStatus> request() => _dataSource.requestAccess();

  @override
  Future<void> openSystemSettings() => _dataSource.openSettings();

  @override
  Future<void> skipOnboarding() => _dataSource.markSkipped();
}
