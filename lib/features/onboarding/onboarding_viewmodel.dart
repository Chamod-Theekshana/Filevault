import 'package:filevault/core/di/providers.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/domain/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  const OnboardingState({
    this.status = StoragePermissionStatus.unknown,
    this.busy = false,
    this.usesAllFilesAccess = true,
    this.onboardingDone = false,
    this.checked = false,
  });

  final StoragePermissionStatus status;
  final bool busy;
  final bool usesAllFilesAccess;
  final bool onboardingDone;

  /// True once the first status read completed (splash can decide).
  final bool checked;

  bool get canEnterApp => status == StoragePermissionStatus.granted || onboardingDone;

  OnboardingState copyWith({
    StoragePermissionStatus? status,
    bool? busy,
    bool? usesAllFilesAccess,
    bool? onboardingDone,
    bool? checked,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      busy: busy ?? this.busy,
      usesAllFilesAccess: usesAllFilesAccess ?? this.usesAllFilesAccess,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      checked: checked ?? this.checked,
    );
  }
}

final NotifierProvider<OnboardingViewModel, OnboardingState> onboardingProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(OnboardingViewModel.new);

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    Future<void>.microtask(refresh);
    return const OnboardingState();
  }

  PermissionRepository get _permissions => ref.read(permissionRepositoryProvider);
  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  Future<void> refresh() async {
    final StoragePermissionStatus status = await _permissions.currentStatus();
    final bool allFiles = await _permissions.usesAllFilesAccess;
    final bool done = await _settings.isOnboardingDone();
    state = state.copyWith(
      status: status,
      usesAllFilesAccess: allFiles,
      onboardingDone: done,
      checked: true,
      busy: false,
    );
  }

  Future<void> grantAccess() async {
    state = state.copyWith(busy: true);
    StoragePermissionStatus status = await _permissions.request();
    if (status == StoragePermissionStatus.permanentlyDenied) {
      await _permissions.openSystemSettings();
      status = await _permissions.currentStatus();
    }
    if (status == StoragePermissionStatus.granted) {
      await _settings.setOnboardingDone(true);
      await _permissions.ensureNotificationPermission();
    }
    state = state.copyWith(
      status: status,
      busy: false,
      onboardingDone: status == StoragePermissionStatus.granted || state.onboardingDone,
    );
  }

  Future<void> openSettings() async {
    state = state.copyWith(busy: true);
    await _permissions.openSystemSettings();
    await refresh();
  }

  Future<void> skip() async {
    await _settings.setOnboardingDone(true);
    state = state.copyWith(onboardingDone: true);
  }
}
