import 'dart:convert';
import 'dart:typed_data';

import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/data/services/vault_crypto_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of an App Lock PIN check.
enum PinCheck { ok, wrong, coolingDown }

/// Credential store for App Lock.
///
/// The PIN itself is never stored: only a random salt and a PBKDF2-SHA256
/// hash of the PIN, kept in Android Keystore-backed secure storage. Wrong
/// attempts are counted and trigger a cooldown, like the Secure Folder.
class AppLockService {
  AppLockService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
    VaultCryptoService crypto = const VaultCryptoService(),
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _auth = localAuth ?? LocalAuthentication(),
        _crypto = crypto;

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;
  final VaultCryptoService _crypto;

  static const String _saltKey = 'filevault.applock.salt';
  static const String _hashKey = 'filevault.applock.hash';
  static const int _iterations = 60000;

  Future<bool> hasPin() async {
    try {
      return (await _storage.read(key: _hashKey)) != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    final Uint8List salt = VaultCryptoService.randomBytes(16);
    final Uint8List hash = await _crypto.deriveKey(pin, salt, iterations: _iterations);
    await _storage.write(key: _saltKey, value: base64Encode(salt));
    await _storage.write(key: _hashKey, value: base64Encode(hash));
    await _resetAttempts();
  }

  Future<void> clear() async {
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _hashKey);
    await _resetAttempts();
  }

  /// Seconds left in the cooldown after too many wrong PINs (0 = none).
  Future<int> cooldownRemaining() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int until = prefs.getInt(AppConstants.prefsAppLockLockedUntil) ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;
    return until > now ? ((until - now) / 1000).ceil() : 0;
  }

  /// Wrong attempts left before the next cooldown.
  Future<int> attemptsLeft() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int used = prefs.getInt(AppConstants.prefsAppLockAttempts) ?? 0;
    return (AppConstants.vaultMaxAttempts - used).clamp(0, AppConstants.vaultMaxAttempts);
  }

  Future<PinCheck> verifyPin(String pin) async {
    if (await cooldownRemaining() > 0) return PinCheck.coolingDown;
    final String? saltText = await _storage.read(key: _saltKey);
    final String? hashText = await _storage.read(key: _hashKey);
    if (saltText == null || hashText == null) return PinCheck.wrong;
    final Uint8List expected = base64Decode(hashText);
    final Uint8List actual =
        await _crypto.deriveKey(pin, base64Decode(saltText), iterations: _iterations);
    if (_constantTimeEquals(expected, actual)) {
      await _resetAttempts();
      return PinCheck.ok;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int attempts = (prefs.getInt(AppConstants.prefsAppLockAttempts) ?? 0) + 1;
    if (attempts >= AppConstants.vaultMaxAttempts) {
      await prefs.setInt(
        AppConstants.prefsAppLockLockedUntil,
        DateTime.now().millisecondsSinceEpoch + AppConstants.vaultCooldownSeconds * 1000,
      );
      await prefs.remove(AppConstants.prefsAppLockAttempts);
      return PinCheck.coolingDown;
    }
    await prefs.setInt(AppConstants.prefsAppLockAttempts, attempts);
    return PinCheck.wrong;
  }

  Future<void> _resetAttempts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefsAppLockAttempts);
    await prefs.remove(AppConstants.prefsAppLockLockedUntil);
  }

  Future<bool> biometricsAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system biometric prompt. Returns true when the user verified.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }

  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
