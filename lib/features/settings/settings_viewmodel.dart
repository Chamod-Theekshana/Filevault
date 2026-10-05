import 'package:filevault/core/di/repository_providers.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/domain/models/storage_permission_status.dart';
import 'package:filevault/domain/repositories/permission_repository.dart';
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
    await _settings.saveThemeMode(mode);
    state = state.copyWith(settings: state.settings.copyWith(themeMode: mode));
  }

  Future<void> setAccent(int argb) async {
    await _settings.saveAccentColor(argb);
    state = state.copyWith(settings: state.settings.copyWith(accentArgb: argb));
  }

  Future<void> setShowHidden(bool value) async {
    await _settings.saveShowHidden(value);
    state = state.copyWith(settings: state.settings.copyWith(showHiddenFiles: value));
  }

  Future<void> setConfirmDelete(bool value) async {
    await _settings.saveConfirmBeforeDelete(value);
    state = state.copyWith(settings: state.settings.copyWith(confirmBeforeDelete: value));
  }

  Future<void> setTrashDays(int days) async {
    await _settings.saveTrashAutoCleanDays(days);
    state = state.copyWith(settings: state.settings.copyWith(trashAutoCleanDays: days));
  }

  Future<void> setDefaultViewMode(String mode) async {
    await _settings.saveDefaultViewMode(mode);
    state = state.copyWith(settings: state.settings.copyWith(defaultViewMode: mode));
  }

  Future<void> setDefaultSort(String sort) async {
    await _settings.saveDefaultSort(sort);
    state = state.copyWith(settings: state.settings.copyWith(defaultSort: sort));
  }
}
