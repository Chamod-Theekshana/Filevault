import 'package:filevault/domain/models/app_settings.dart';

/// Persisted user preferences. The filesystem is never stored here.
abstract class SettingsRepository {
  Future<AppSettings> load();

  Future<void> saveThemeMode(AppThemeMode mode);

  Future<void> saveAccentColor(int argb);

  Future<void> saveShowHidden(bool value);

  Future<void> saveTrashAutoCleanDays(int days);

  Future<void> saveConfirmBeforeDelete(bool value);

  Future<void> saveDefaultViewMode(String mode);

  Future<void> saveDefaultSort(String sort);
}
