/// App-wide constants. Keep platform specifics (paths, SDK levels) here so
/// the rest of the code never hard-codes them.
abstract final class AppConstants {
  static const String appName = 'FileVault';
  static const String platformChannel = 'com.filevault/platform';

  /// Android 11 (API 30) introduced MANAGE_EXTERNAL_STORAGE.
  static const int scopedStorageSdk = 30;

  /// Android 13 (API 33) introduced runtime notification permission.
  static const int notificationPermissionSdk = 33;

  static const String primaryStoragePath = '/storage/emulated/0';
  static const String downloadsFolder = 'Download';
  static const String trashFolderName = '.filevault_trash';
  static const String vaultFolderName = 'vault';
  static const String thumbCacheFolderName = 'thumbs';

  static const List<String> restrictedFolders = <String>[
    '/storage/emulated/0/Android/data',
    '/storage/emulated/0/Android/obb',
  ];

  // Shared preferences keys.
  static const String prefsThemeMode = 'theme_mode';
  static const String prefsAccentColor = 'accent_color';
  static const String prefsShowHidden = 'show_hidden';
  static const String prefsTrashAutoCleanDays = 'trash_auto_clean_days';
  static const String prefsConfirmDelete = 'confirm_delete';
  static const String prefsDefaultViewMode = 'default_view_mode';
  static const String prefsDefaultSort = 'default_sort';
  static const String prefsSortDirection = 'default_sort_direction';
  static const String prefsFoldersFirst = 'folders_first';
  static const String prefsOnboardingDone = 'onboarding_done';
  static const String prefsVaultBiometric = 'vault_biometric';
  static const String prefsVaultAutoLockMinutes = 'vault_auto_lock_minutes';
  static const String prefsRecentSearches = 'recent_searches';
  static const String prefsLastIndexAt = 'last_index_at';
  static const String prefsAppLockEnabled = 'app_lock_enabled';
  static const String prefsAppLockBiometric = 'app_lock_biometric';
  static const String prefsAppLockTimeout = 'app_lock_timeout_seconds';
  static const String prefsSecureScreens = 'secure_screens';
  static const String prefsAppLockAttempts = 'app_lock_failed_attempts';
  static const String prefsAppLockLockedUntil = 'app_lock_locked_until';

  static const int defaultAccentColor = 0xFF0B6E99;
  static const int defaultTrashAutoCleanDays = 30;
  static const int maxRecentFiles = 40;
  static const int maxRecentSearches = 8;
  static const int largeFileThresholdBytes = 100 * 1024 * 1024;
  static const int textEditorMaxBytes = 4 * 1024 * 1024;
  static const int copyChunkBytes = 512 * 1024;
  static const int vaultChunkBytes = 1024 * 1024;

  /// Chunk size used by the native (Kotlin) vault engine. Readers take the
  /// chunk size from each file's header, so both sizes stay compatible.
  static const int vaultNativeChunkBytes = 4 * 1024 * 1024;
  static const int vaultPbkdf2Iterations = 120000;
  static const int vaultMaxAttempts = 5;
  static const int vaultCooldownSeconds = 30;
  static const int listBatchSize = 200;
}
