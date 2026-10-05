import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/utils/app_logger.dart';
import 'package:filevault/domain/models/storage_permission_status.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform storage permission checks. Never imported by ViewModels.
class StoragePermissionDataSource {
  StoragePermissionDataSource({
    DeviceInfoPlugin? deviceInfo,
    Future<SharedPreferences> Function()? preferences,
  })  : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _preferences = preferences ?? SharedPreferences.getInstance;

  final DeviceInfoPlugin _deviceInfo;
  final Future<SharedPreferences> Function() _preferences;

  Future<StoragePermissionStatus> readStatus() async {
    final SharedPreferences prefs = await _preferences();
    if (prefs.getBool(AppConstants.prefsOnboardingSkipped) ?? false) {
      final StoragePermissionStatus live = await _platformStatus();
      if (live == StoragePermissionStatus.granted) {
        return StoragePermissionStatus.granted;
      }
      return StoragePermissionStatus.skipped;
    }
    return _platformStatus();
  }

  Future<StoragePermissionStatus> requestAccess() async {
    if (!Platform.isAndroid) {
      return StoragePermissionStatus.granted;
    }
    final int sdk = await _sdkInt();
    PermissionStatus status;
    if (sdk >= AppConstants.scopedStorageSdk) {
      status = await Permission.manageExternalStorage.request();
    } else {
      status = await Permission.storage.request();
    }
    return _map(status);
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> markSkipped() async {
    final SharedPreferences prefs = await _preferences();
    await prefs.setBool(AppConstants.prefsOnboardingSkipped, true);
  }

  Future<StoragePermissionStatus> _platformStatus() async {
    if (!Platform.isAndroid) {
      return StoragePermissionStatus.granted;
    }
    final int sdk = await _sdkInt();
    final Permission permission = sdk >= AppConstants.scopedStorageSdk
        ? Permission.manageExternalStorage
        : Permission.storage;
    return _map(await permission.status);
  }

  Future<int> _sdkInt() async {
    try {
      final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
      return info.version.sdkInt;
    } catch (error, stack) {
      appLogger.w('Failed to read Android SDK', error: error, stackTrace: stack);
      return AppConstants.scopedStorageSdk;
    }
  }

  StoragePermissionStatus _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return StoragePermissionStatus.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return StoragePermissionStatus.permanentlyDenied;
    }
    return StoragePermissionStatus.denied;
  }
}
