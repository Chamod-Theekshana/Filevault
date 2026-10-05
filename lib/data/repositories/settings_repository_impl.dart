import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/data/services/permission_data_source.dart';
import 'package:filevault/data/services/platform_channel_service.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:filevault/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({Future<SharedPreferences> Function()? preferences})
      : _prefs = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefs;

  @override
  Future<AppSettings> load() async {
    final SharedPreferences prefs = await _prefs();
    return AppSettings(
      themeMode: switch (prefs.getString(AppConstants.prefsThemeMode)) {
        'light' => AppThemeMode.light,
        'dark' => AppThemeMode.dark,
        _ => AppThemeMode.system,
      },
      accentArgb: prefs.getInt(AppConstants.prefsAccentColor) ?? AppConstants.defaultAccentColor,
      showHiddenFiles: prefs.getBool(AppConstants.prefsShowHidden) ?? false,
      trashAutoCleanDays: prefs.getInt(AppConstants.prefsTrashAutoCleanDays) ??
          AppConstants.defaultTrashAutoCleanDays,
      confirmBeforeDelete: prefs.getBool(AppConstants.prefsConfirmDelete) ?? true,
      defaultViewMode: prefs.getString(AppConstants.prefsDefaultViewMode) == 'grid'
          ? ViewMode.grid
          : ViewMode.list,
      defaultSort: SortSpec.fromNames(
        prefs.getString(AppConstants.prefsDefaultSort) ?? 'name',
        prefs.getString(AppConstants.prefsSortDirection) ?? 'asc',
        prefs.getBool(AppConstants.prefsFoldersFirst) ?? true,
      ),
      vaultBiometric: prefs.getBool(AppConstants.prefsVaultBiometric) ?? false,
      vaultAutoLockMinutes: prefs.getInt(AppConstants.prefsVaultAutoLockMinutes) ?? 0,
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.setString(AppConstants.prefsThemeMode, s.themeMode.name);
    await prefs.setInt(AppConstants.prefsAccentColor, s.accentArgb);
    await prefs.setBool(AppConstants.prefsShowHidden, s.showHiddenFiles);
    await prefs.setInt(AppConstants.prefsTrashAutoCleanDays, s.trashAutoCleanDays);
    await prefs.setBool(AppConstants.prefsConfirmDelete, s.confirmBeforeDelete);
    await prefs.setString(AppConstants.prefsDefaultViewMode, s.defaultViewMode.name);
    await prefs.setString(AppConstants.prefsDefaultSort, s.defaultSort.field.name);
    await prefs.setString(AppConstants.prefsSortDirection, s.defaultSort.direction.name);
    await prefs.setBool(AppConstants.prefsFoldersFirst, s.defaultSort.foldersFirst);
    await prefs.setBool(AppConstants.prefsVaultBiometric, s.vaultBiometric);
    await prefs.setInt(AppConstants.prefsVaultAutoLockMinutes, s.vaultAutoLockMinutes);
  }

  @override
  Future<bool> isOnboardingDone() async =>
      (await _prefs()).getBool(AppConstants.prefsOnboardingDone) ?? false;

  @override
  Future<void> setOnboardingDone(bool done) async =>
      (await _prefs()).setBool(AppConstants.prefsOnboardingDone, done);
}

class PermissionRepositoryImpl implements PermissionRepository {
  const PermissionRepositoryImpl(this._source, this._platform);

  final PermissionDataSource _source;
  final PlatformChannelService _platform;

  @override
  Future<StoragePermissionStatus> currentStatus() => _source.status();

  @override
  Future<StoragePermissionStatus> request() => _source.request();

  @override
  Future<void> openSystemSettings() async {
    if (await _source.usesAllFilesAccess()) {
      await _platform.openAllFilesAccessSettings();
    } else {
      await _source.openSettings();
    }
  }

  @override
  Future<bool> get usesAllFilesAccess => _source.usesAllFilesAccess();

  @override
  Future<void> ensureNotificationPermission() => _source.ensureNotifications();
}
