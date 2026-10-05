import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/utils/app_logger.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';

/// Storage permission plumbing for Android 8 – 15.
class PermissionDataSource {
  PermissionDataSource({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;
  int? _sdk;

  Future<int> sdkInt() async {
    final int? cached = _sdk;
    if (cached != null) return cached;
    if (!Platform.isAndroid) return _sdk = 0;
    try {
      final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
      return _sdk = info.version.sdkInt;
    } catch (e) {
      appLogger.w('Unable to read SDK level: $e');
      return _sdk = AppConstants.scopedStorageSdk;
    }
  }

  Future<bool> usesAllFilesAccess() async =>
      Platform.isAndroid && await sdkInt() >= AppConstants.scopedStorageSdk;

  Future<Permission> _storagePermission() async =>
      await usesAllFilesAccess() ? Permission.manageExternalStorage : Permission.storage;

  Future<StoragePermissionStatus> status() async {
    if (!Platform.isAndroid) return StoragePermissionStatus.granted;
    final Permission permission = await _storagePermission();
    return _map(await permission.status);
  }

  Future<StoragePermissionStatus> request() async {
    if (!Platform.isAndroid) return StoragePermissionStatus.granted;
    final Permission permission = await _storagePermission();
    return _map(await permission.request());
  }

  Future<void> ensureNotifications() async {
    if (!Platform.isAndroid) return;
    if (await sdkInt() < AppConstants.notificationPermissionSdk) return;
    try {
      final PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) await Permission.notification.request();
    } catch (_) {}
  }

  Future<void> openSettings() => openAppSettings();

  StoragePermissionStatus _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return StoragePermissionStatus.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return StoragePermissionStatus.permanentlyDenied;
    }
    return StoragePermissionStatus.denied;
  }
}
