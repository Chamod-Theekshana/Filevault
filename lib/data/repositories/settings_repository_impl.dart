import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<AppSettings> load() async {
    final SharedPreferences prefs = await _preferences();
    return AppSettings(
      themeMode: _themeMode(prefs.getString(AppConstants.prefsThemeMode)),
      accentArgb:
          prefs.getInt(AppConstants.prefsAccentColor) ?? AppConstants.defaultAccentColor,
      showHiddenFiles: prefs.getBool(AppConstants.prefsShowHidden) ?? false,
      trashAutoCleanDays: prefs.getInt(AppConstants.prefsTrashAutoCleanDays) ??
          AppConstants.defaultTrashAutoCleanDays,
      confirmBeforeDelete: prefs.getBool(AppConstants.prefsConfirmDelete) ?? true,
      defaultViewMode: prefs.getString(AppConstants.prefsDefaultViewMode) ?? 'list',
      defaultSort: prefs.getString(AppConstants.prefsDefaultSort) ?? 'name',
    );
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    final SharedPreferences prefs = await _preferences();
    await prefs.setString(AppConstants.prefsThemeMode, mode.name);
  }

  @override
  Future<void> saveAccentColor(int argb) async {
    final SharedPreferences prefs = await _preferences();
    await prefs.setInt(AppConstants.prefsAccentColor, argb);
  }

  @override
  Future<void> saveShowHidden(bool value) async {
    final SharedPreferences prefs = await _preferences();
    await prefs.setBool(AppConstants.prefsShowHidden, value);
  }

  @override
  Future<void> saveTrashAutoCleanDays(int days) async {
    final SharedPreferences prefs = await _preferences();
    await prefs.setInt(AppConstants.prefsTrashAutoCleanDays, days);
  }

  @override
  Future<void> saveConfirmBeforeDelete(bool value) async {
    final SharedPreferences prefs = await _preferences();
    await prefs.setBool(AppConstants.prefsConfirmDelete, value);
  }

  @override
  Future<void> saveDefaultViewMode(String mode) async {
    final SharedPreferences prefs = await _preferences();
    await prefs.setString(AppConstants.prefsDefaultViewMode, mode);
  }

  @override
  Future<void> saveDefaultSort(String sort) async {
    final SharedPreferences prefs = await _preferences();
    await prefs.setString(AppConstants.prefsDefaultSort, sort);
  }

  AppThemeMode _themeMode(String? raw) {
    return switch (raw) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }
}
