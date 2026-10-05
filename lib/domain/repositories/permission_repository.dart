import 'package:filevault/domain/models/storage_permission_status.dart';

/// Single source of truth for storage permission checks.
abstract class PermissionRepository {
  /// Current OS-level status plus any in-app skip flag.
  Future<StoragePermissionStatus> currentStatus();

  /// Requests READ/WRITE below Android 11, MANAGE_EXTERNAL_STORAGE on 11+.
  Future<StoragePermissionStatus> request();

  /// Opens the system application settings screen.
  Future<void> openSystemSettings();

  /// Records that the user chose "Not now" on onboarding.
  Future<void> skipOnboarding();
}
