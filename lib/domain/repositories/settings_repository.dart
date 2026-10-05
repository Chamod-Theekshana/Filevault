import 'package:filevault/domain/models/app_settings.dart';

/// Persisted user preferences.
abstract class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);

  Future<bool> isOnboardingDone();

  Future<void> setOnboardingDone(bool done);
}

/// Storage permission state and requests.
abstract class PermissionRepository {
  Future<StoragePermissionStatus> currentStatus();

  Future<StoragePermissionStatus> request();

  Future<void> openSystemSettings();

  /// True on Android 11+ where "All files access" is the relevant grant.
  Future<bool> get usesAllFilesAccess;

  Future<void> ensureNotificationPermission();
}
