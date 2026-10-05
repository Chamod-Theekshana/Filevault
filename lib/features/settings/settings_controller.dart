import 'package:filevault/core/di/providers.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:filevault/domain/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings loaded before `runApp` and injected via ProviderScope override.
final Provider<AppSettings> initialSettingsProvider =
    Provider<AppSettings>((Ref ref) => const AppSettings());

/// Global, app-wide settings state. Persists every change immediately.
final NotifierProvider<SettingsController, AppSettings> settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  Future<void> _update(AppSettings next) async {
    state = next;
    await _repo.save(next);
  }

  Future<void> setThemeMode(AppThemeMode mode) => _update(state.copyWith(themeMode: mode));

  Future<void> setAccent(int argb) => _update(state.copyWith(accentArgb: argb));

  Future<void> setShowHidden(bool value) => _update(state.copyWith(showHiddenFiles: value));

  Future<void> setConfirmDelete(bool value) =>
      _update(state.copyWith(confirmBeforeDelete: value));

  Future<void> setTrashDays(int days) => _update(state.copyWith(trashAutoCleanDays: days));

  Future<void> setDefaultViewMode(ViewMode mode) =>
      _update(state.copyWith(defaultViewMode: mode));

  Future<void> setDefaultSort(SortSpec sort) => _update(state.copyWith(defaultSort: sort));

  Future<void> setVaultBiometric(bool value) => _update(state.copyWith(vaultBiometric: value));

  Future<void> setVaultAutoLock(int minutes) =>
      _update(state.copyWith(vaultAutoLockMinutes: minutes));
}
