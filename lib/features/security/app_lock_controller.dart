import 'dart:async';

import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/utils/lifecycle_guard.dart';
import 'package:filevault/data/services/app_lock_service.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLockState {
  const AppLockState({
    this.locked = false,
    this.busy = false,
    this.error,
    this.attemptsLeft = AppConstants.vaultMaxAttempts,
    this.cooldownSeconds = 0,
    this.biometricsAvailable = false,
  });

  /// True while the lock screen must cover the app.
  final bool locked;
  final bool busy;

  /// 'wrongPin', 'cooldown' or 'biometric'.
  final String? error;
  final int attemptsLeft;
  final int cooldownSeconds;
  final bool biometricsAvailable;

  AppLockState copyWith({
    bool? locked,
    bool? busy,
    String? error,
    bool clearError = false,
    int? attemptsLeft,
    int? cooldownSeconds,
    bool? biometricsAvailable,
  }) {
    return AppLockState(
      locked: locked ?? this.locked,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
    );
  }
}

final NotifierProvider<AppLockController, AppLockState> appLockProvider =
    NotifierProvider<AppLockController, AppLockState>(AppLockController.new);

/// App Lock state machine.
///
/// * Cold start: locked whenever App Lock is enabled.
/// * Background: the moment FileVault leaves the screen we remember when; on
///   return it locks again if the configured timeout has passed (immediately
///   by default). With "Immediately" it locks right away when backgrounded so
///   the content never flashes on return.
/// * System prompts FileVault opens itself (fingerprint) never count as
///   leaving the app – see [LifecycleGuard].
class AppLockController extends Notifier<AppLockState> {
  DateTime? _backgroundedAt;
  Timer? _cooldownTimer;

  AppLockService get _service => ref.read(appLockServiceProvider);
  AppSettings get _settings => ref.read(settingsProvider);

  @override
  AppLockState build() {
    ref.onDispose(() => _cooldownTimer?.cancel());
    final bool enabled = ref.read(settingsProvider).appLockEnabled;
    Future<void>.microtask(_refreshMeta);
    return AppLockState(locked: enabled);
  }

  Future<void> _refreshMeta() async {
    final bool bio = await _service.biometricsAvailable();
    final int cooldown = await _service.cooldownRemaining();
    final int attempts = await _service.attemptsLeft();
    state = state.copyWith(
      biometricsAvailable: bio,
      cooldownSeconds: cooldown,
      attemptsLeft: attempts,
      error: cooldown > 0 ? 'cooldown' : null,
    );
    if (cooldown > 0) _startCooldown(cooldown);
  }

  // ------------------------------------------------------------ lifecycle

  void onBackground() {
    if (!_settings.appLockEnabled || LifecycleGuard.active) return;
    _backgroundedAt ??= DateTime.now();
    if (_settings.appLockTimeoutSeconds <= 0) {
      state = state.copyWith(locked: true, clearError: true);
    }
  }

  void onForeground() {
    final DateTime? at = _backgroundedAt;
    _backgroundedAt = null;
    if (!_settings.appLockEnabled || at == null || LifecycleGuard.active) return;
    final int elapsed = DateTime.now().difference(at).inSeconds;
    if (elapsed >= _settings.appLockTimeoutSeconds) {
      state = state.copyWith(locked: true, clearError: true);
    }
  }

  void lockNow() {
    if (!_settings.appLockEnabled) return;
    state = state.copyWith(locked: true, clearError: true);
  }

  // --------------------------------------------------------------- unlock

  Future<bool> unlockWithPin(String pin) async {
    state = state.copyWith(busy: true, clearError: true);
    final PinCheck result = await _service.verifyPin(pin);
    switch (result) {
      case PinCheck.ok:
        state = state.copyWith(
          locked: false,
          busy: false,
          attemptsLeft: AppConstants.vaultMaxAttempts,
          cooldownSeconds: 0,
        );
        return true;
      case PinCheck.wrong:
        state = state.copyWith(
          busy: false,
          error: 'wrongPin',
          attemptsLeft: await _service.attemptsLeft(),
        );
        return false;
      case PinCheck.coolingDown:
        final int seconds = await _service.cooldownRemaining();
        state = state.copyWith(busy: false, error: 'cooldown', cooldownSeconds: seconds);
        _startCooldown(seconds);
        return false;
    }
  }

  Future<bool> unlockWithBiometrics(String reason) async {
    if (!_settings.appLockBiometric || !state.biometricsAvailable) return false;
    state = state.copyWith(busy: true, clearError: true);
    final bool ok = await LifecycleGuard.run(() => _service.authenticate(reason));
    state = state.copyWith(locked: ok ? false : state.locked, busy: false);
    return ok;
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    if (seconds <= 0) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      final int left = state.cooldownSeconds - 1;
      if (left <= 0) {
        timer.cancel();
        state = state.copyWith(
          cooldownSeconds: 0,
          clearError: true,
          attemptsLeft: AppConstants.vaultMaxAttempts,
        );
      } else {
        state = state.copyWith(cooldownSeconds: left);
      }
    });
  }

  // -------------------------------------------------------------- manage

  /// Checks [pin] without unlocking anything (used before turning App Lock
  /// off or changing its PIN).
  Future<bool> verify(String pin) async => (await _service.verifyPin(pin)) == PinCheck.ok;

  Future<void> enable(String pin, {required bool biometric}) async {
    await _service.setPin(pin);
    await ref.read(settingsProvider.notifier).setAppLock(enabled: true, biometric: biometric);
    state = state.copyWith(locked: false, clearError: true);
    await _refreshMeta();
  }

  Future<void> changePin(String pin) async {
    await _service.setPin(pin);
  }

  Future<void> disable() async {
    await _service.clear();
    await ref.read(settingsProvider.notifier).setAppLock(enabled: false);
    _backgroundedAt = null;
    state = state.copyWith(locked: false, clearError: true);
  }

  Future<void> setBiometric(bool value) =>
      ref.read(settingsProvider.notifier).setAppLockBiometric(value);

  Future<bool> biometricsAvailable() => _service.biometricsAvailable();
}
