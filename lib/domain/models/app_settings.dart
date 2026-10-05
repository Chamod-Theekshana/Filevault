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
    );
  }
}

enum StoragePermissionStatus { unknown, granted, denied, permanentlyDenied }
