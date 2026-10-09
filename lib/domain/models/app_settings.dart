import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/domain/models/sort_options.dart';

enum AppThemeMode { system, light, dark }

/// User preferences persisted in SharedPreferences.
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.accentArgb = AppConstants.defaultAccentColor,
    this.showHiddenFiles = false,
    this.trashAutoCleanDays = AppConstants.defaultTrashAutoCleanDays,
    this.confirmBeforeDelete = true,
    this.defaultViewMode = ViewMode.list,
    this.defaultSort = const SortSpec(),
    this.vaultBiometric = false,
    this.vaultAutoLockMinutes = 0,
    this.appLockEnabled = false,
    this.appLockBiometric = false,
    this.appLockTimeoutSeconds = 0,
    this.secureScreens = false,
  });

  final AppThemeMode themeMode;
  final int accentArgb;
  final bool showHiddenFiles;

  /// 0 disables automatic trash cleanup.
  final int trashAutoCleanDays;
  final bool confirmBeforeDelete;
  final ViewMode defaultViewMode;
  final SortSpec defaultSort;
  final bool vaultBiometric;

  /// 0 = lock as soon as the app goes to the background.
  final int vaultAutoLockMinutes;

  /// App Lock: ask for the app PIN / fingerprint when FileVault is opened.
  final bool appLockEnabled;
  final bool appLockBiometric;

  /// How long FileVault may stay in the background before App Lock asks
  /// again. 0 = immediately.
  final int appLockTimeoutSeconds;

  /// Block screenshots and hide app content in the recent-apps screen.
  final bool secureScreens;

  /// FLAG_SECURE should be on for the whole app (the Secure Folder always
  /// turns it on for itself).
  bool get secureWindow => secureScreens || appLockEnabled;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? accentArgb,
    bool? showHiddenFiles,
    int? trashAutoCleanDays,
    bool? confirmBeforeDelete,
    ViewMode? defaultViewMode,
    SortSpec? defaultSort,
    bool? vaultBiometric,
    int? vaultAutoLockMinutes,
    bool? appLockEnabled,
    bool? appLockBiometric,
    int? appLockTimeoutSeconds,
    bool? secureScreens,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentArgb: accentArgb ?? this.accentArgb,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      trashAutoCleanDays: trashAutoCleanDays ?? this.trashAutoCleanDays,
      confirmBeforeDelete: confirmBeforeDelete ?? this.confirmBeforeDelete,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      defaultSort: defaultSort ?? this.defaultSort,
      vaultBiometric: vaultBiometric ?? this.vaultBiometric,
      vaultAutoLockMinutes: vaultAutoLockMinutes ?? this.vaultAutoLockMinutes,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockBiometric: appLockBiometric ?? this.appLockBiometric,
      appLockTimeoutSeconds: appLockTimeoutSeconds ?? this.appLockTimeoutSeconds,
      secureScreens: secureScreens ?? this.secureScreens,
    );
  }
}

enum StoragePermissionStatus { unknown, granted, denied, permanentlyDenied }
