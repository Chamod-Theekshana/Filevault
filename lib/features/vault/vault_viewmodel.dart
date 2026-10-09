import 'dart:async';

import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/core/utils/lifecycle_guard.dart';
import 'package:filevault/domain/models/vault_item.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VaultState {
  const VaultState({
    this.status = VaultStatus.notConfigured,
    this.items = const <VaultItem>[],
    this.selected = const <int>{},
    this.totalBytes = 0,
    this.busy = false,
    this.loading = true,
    this.biometricsAvailable = false,
    this.attemptsLeft = AppConstants.vaultMaxAttempts,
    this.cooldownSeconds = 0,
    this.error,
  });

  final VaultStatus status;
  final List<VaultItem> items;
  final Set<int> selected;
  final int totalBytes;
  final bool busy;
  final bool loading;
  final bool biometricsAvailable;
  final int attemptsLeft;
  final int cooldownSeconds;

  /// Localisation key for the last error, or null.
  final String? error;

  bool get selecting => selected.isNotEmpty;
  bool get locked => status == VaultStatus.locked;
  bool get unlocked => status == VaultStatus.unlocked;

  List<VaultItem> get selectedItems =>
      items.where((VaultItem i) => selected.contains(i.id)).toList(growable: false);

  VaultState copyWith({
    VaultStatus? status,
    List<VaultItem>? items,
    Set<int>? selected,
    int? totalBytes,
    bool? busy,
    bool? loading,
    bool? biometricsAvailable,
    int? attemptsLeft,
    int? cooldownSeconds,
    String? error,
    bool clearError = false,
  }) {
    return VaultState(
      status: status ?? this.status,
      items: items ?? this.items,
      selected: selected ?? this.selected,
      totalBytes: totalBytes ?? this.totalBytes,
      busy: busy ?? this.busy,
      loading: loading ?? this.loading,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final NotifierProvider<VaultViewModel, VaultState> vaultProvider =
    NotifierProvider<VaultViewModel, VaultState>(VaultViewModel.new);

class VaultViewModel extends Notifier<VaultState> {
  Timer? _cooldownTimer;

  @override
  VaultState build() {
    ref.listen(operationFinishedProvider, (_, _) => load());
    ref.onDispose(() => _cooldownTimer?.cancel());
    Future<void>.microtask(load);
    return const VaultState();
  }

  Future<void> load() async {
    final bool configured = await ref.read(vaultRepositoryProvider).isConfigured();
    final bool bio = await ref.read(vaultRepositoryProvider).biometricsAvailable();
    if (!configured) {
      state = state.copyWith(
        status: VaultStatus.notConfigured,
        loading: false,
        biometricsAvailable: bio,
        items: const <VaultItem>[],
      );
      return;
    }
    if (!ref.read(vaultRepositoryProvider).isUnlocked) {
      state = state.copyWith(
        status: VaultStatus.locked,
        loading: false,
        biometricsAvailable: bio,
        items: const <VaultItem>[],
      );
      return;
    }
    final List<VaultItem> items = await ref.read(vaultRepositoryProvider).items();
    final int bytes = await ref.read(vaultRepositoryProvider).totalBytes();
    state = state.copyWith(
      status: VaultStatus.unlocked,
      items: items,
      totalBytes: bytes,
      loading: false,
      biometricsAvailable: bio,
      selected: state.selected.where((int id) => items.any((VaultItem i) => i.id == id)).toSet(),
    );
  }

  Future<bool> setup(String pin, {bool enableBiometrics = false}) async {
    state = state.copyWith(busy: true, clearError: true);
    final Result<void> r = await ref.read(vaultRepositoryProvider).setup(pin);
    if (r.isFailure) {
      state = state.copyWith(busy: false, error: 'io');
      return false;
    }
    if (enableBiometrics) {
      await ref.read(vaultRepositoryProvider).setBiometricEnabled(true);
      await ref.read(settingsProvider.notifier).setVaultBiometric(true);
    }
    state = state.copyWith(busy: false);
    await load();
    return true;
  }

  Future<bool> unlock(String pin) async {
    state = state.copyWith(busy: true, clearError: true);
    final Result<void> r = await ref.read(vaultRepositoryProvider).unlock(pin);
    final Failure? failure = r.failureOrNull;
    if (failure == null) {
      state = state.copyWith(busy: false, attemptsLeft: AppConstants.vaultMaxAttempts);
      await load();
      return true;
    }
    switch (failure) {
      case WrongPinFailure(:final int attemptsLeft):
        state = state.copyWith(busy: false, error: 'wrongPin', attemptsLeft: attemptsLeft);
      case VaultLockedFailure(:final int secondsRemaining):
        state = state.copyWith(busy: false, error: 'cooldown', cooldownSeconds: secondsRemaining);
        _startCooldown(secondsRemaining);
      default:
        state = state.copyWith(busy: false, error: 'io');
    }
    return false;
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
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

  Future<bool> unlockWithBiometrics() async {
    state = state.copyWith(busy: true, clearError: true);
    // The system prompt must not count as "leaving the app" (auto-lock).
    final Result<void> r =
        await LifecycleGuard.run(() => ref.read(vaultRepositoryProvider).unlockWithBiometrics());
    state = state.copyWith(busy: false, error: r.isFailure ? 'biometric' : null);
    if (r.isSuccess) await load();
    return r.isSuccess;
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    state = state.copyWith(busy: true, clearError: true);
    final Result<void> r =
        await ref.read(vaultRepositoryProvider).changePin(currentPin, newPin);
    state = state.copyWith(busy: false, error: r.isFailure ? 'wrongPin' : null);
    if (r.isSuccess && ref.read(settingsProvider).vaultBiometric) {
      await ref.read(vaultRepositoryProvider).setBiometricEnabled(true);
    }
    return r.isSuccess;
  }

  /// Turning fingerprint unlock on needs the vault key, so it only works
  /// while the Secure Folder is open. Returns false when it could not be
  /// changed (the setting is then left untouched).
  Future<bool> setBiometrics(bool enabled) async {
    final Result<void> r = await ref.read(vaultRepositoryProvider).setBiometricEnabled(enabled);
    if (r.isFailure) return false;
    await ref.read(settingsProvider.notifier).setVaultBiometric(enabled);
    return true;
  }

  /// Wipes the key. Decrypted preview copies are removed by the vault screen
  /// itself (on open and on close) – not here, because an auto-lock can fire
  /// while another app is still reading a file the user opened from the vault.
  void lock() {
    ref.read(vaultRepositoryProvider).lock();
    if (state.status == VaultStatus.notConfigured) return;
    state = state.copyWith(
      status: VaultStatus.locked,
      items: const <VaultItem>[],
      selected: <int>{},
      clearError: true,
    );
  }

  Future<void> reset() async {
    await ref.read(vaultRepositoryProvider).reset();
    await ref.read(settingsProvider.notifier).setVaultBiometric(false);
    await load();
  }

  void toggle(int id) {
    final Set<int> next = Set<int>.of(state.selected);
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(selected: next);
  }

  void selectAll() => state = state.copyWith(selected: state.items.map((VaultItem i) => i.id).toSet());

  void clearSelection() => state = state.copyWith(selected: <int>{});

  void addFiles(List<String> paths) {
    if (paths.isEmpty) return;
    ref.read(operationsProvider.notifier).enqueueEncrypt(paths);
  }

  void exportSelected() {
    final List<VaultItem> items = state.selectedItems;
    if (items.isEmpty) return;
    ref.read(operationsProvider.notifier).enqueueDecrypt(items);
    clearSelection();
  }

  Future<void> deleteSelected() async {
    for (final VaultItem item in state.selectedItems) {
      await ref.read(vaultRepositoryProvider).deleteItem(item);
    }
    clearSelection();
    await load();
  }

  Future<String?> decryptForViewing(
    VaultItem item, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final Result<String> r = await ref
        .read(vaultRepositoryProvider)
        .decryptToTemp(item, onProgress: onProgress, cancelToken: cancelToken);
    return r.valueOrNull;
  }
}
