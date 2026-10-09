import 'package:filevault/core/di/providers.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:filevault/domain/repositories/settings_repository.dart';
import 'package:filevault/features/settings/settings_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final NotifierProvider<SettingsViewModel, SettingsState> settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, SettingsState>(SettingsViewModel.new);

class SettingsViewModel extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    Future<void>.microtask(_hydrate);
    return const SettingsState();
  }

  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  PermissionRepository get _permissions => ref.read(permissionRepositoryProvider);

  Future<void> _hydrate() async {
    final AppSettings settings = await _settings.load();
    final StoragePermissionStatus permission = await _permissions.currentStatus();
    String version = '1.0.0';
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    state = SettingsState(
      settings: settings,
      versionLabel: version,
      permissionStatus: permission,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final AppSettings newSettings = state.settings.copyWith(themeMode: mode);
    await _settings.save(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> setAccent(int argb) async {
    final AppSettings newSettings = state.settings.copyWith(accentArgb: argb);
    await _settings.save(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> setShowHidden(bool value) async {
    final AppSettings newSettings = state.settings.copyWith(showHiddenFiles: value);
    await _settings.save(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> setConfirmDelete(bool value) async {
    final AppSettings newSettings = state.settings.copyWith(confirmBeforeDelete: value);
    await _settings.save(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> setTrashDays(int days) async {
    final AppSettings newSettings = state.settings.copyWith(trashAutoCleanDays: days);
    await _settings.save(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> setDefaultViewMode(ViewMode mode) async {
    final AppSettings newSettings = state.settings.copyWith(defaultViewMode: mode);
    await _settings.save(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> setDefaultSort(SortSpec sort) async {
    final AppSettings newSettings = state.settings.copyWith(defaultSort: sort);
    await _settings.save(newSettings);
    state = state.copyWith(settings: newSettings);
  }
}
