import 'package:filevault/core/di/repository_providers.dart';
import 'package:filevault/domain/models/storage_permission_status.dart';
import 'package:filevault/domain/repositories/permission_repository.dart';
import 'package:filevault/features/onboarding/onboarding_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<OnboardingViewModel, OnboardingState>
    onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(OnboardingViewModel.new);

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    Future<void>.microtask(refresh);
    return const OnboardingState();
  }

  PermissionRepository get _repo => ref.read(permissionRepositoryProvider);

  Future<void> refresh() async {
    state = state.copyWith(isBusy: true);
    final StoragePermissionStatus status = await _repo.currentStatus();
    state = state.copyWith(status: status, isBusy: false);
  }

  Future<void> grantAccess() async {
    state = state.copyWith(isBusy: true);
    final StoragePermissionStatus status = await _repo.request();
    if (status == StoragePermissionStatus.permanentlyDenied) {
      await _repo.openSystemSettings();
    }
    final StoragePermissionStatus latest = await _repo.currentStatus();
    state = state.copyWith(status: latest, isBusy: false);
  }

  Future<void> skip() async {
    await _repo.skipOnboarding();
    state = state.copyWith(status: StoragePermissionStatus.skipped, isBusy: false);
  }

  Future<void> openSettings() async {
    state = state.copyWith(isBusy: true);
    await _repo.openSystemSettings();
    final StoragePermissionStatus status = await _repo.currentStatus();
    state = state.copyWith(status: status, isBusy: false);
  }
}
