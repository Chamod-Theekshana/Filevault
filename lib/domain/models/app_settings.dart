import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

enum AppThemeMode { system, light, dark }

/// Persisted settings. Independent of Flutter ThemeMode.
@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(0xFF0B6E99) int accentArgb,
    @Default(false) bool showHiddenFiles,
    @Default(30) int trashAutoCleanDays,
    @Default(true) bool confirmBeforeDelete,
    @Default('list') String defaultViewMode,
    @Default('name') String defaultSort,
  }) = _AppSettings;
}
