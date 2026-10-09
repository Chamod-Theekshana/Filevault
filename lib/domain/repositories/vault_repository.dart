import 'dart:typed_data';

import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/domain/models/vault_item.dart';

/// Secure Folder: PIN-protected, AES-256-GCM encrypted storage inside the
/// app's private directory. The master key only exists in memory while the
/// vault is unlocked.
abstract class VaultRepository {
  Future<bool> isConfigured();

  bool get isUnlocked;

  /// Creates the vault with [pin]. Fails if one already exists.
  Future<Result<void>> setup(String pin);

  Future<Result<void>> unlock(String pin);

  /// Unlocks using the key stored behind the device biometric prompt.
  Future<Result<void>> unlockWithBiometrics();

  Future<bool> biometricsAvailable();

  Future<Result<void>> setBiometricEnabled(bool enabled);

  Future<Result<void>> changePin(String currentPin, String newPin);

  void lock();

  /// A private copy of the master key for a long-running operation, or null
  /// while the vault is locked. Operations take a copy when they start so
  /// that locking the Secure Folder UI (which wipes the in-memory key) never
  /// corrupts a transfer that is already running. Callers must zero the copy
  /// when they are done.
  Uint8List? sessionKey();

  /// Permanently destroys the vault and every file in it.
  Future<Result<void>> reset();

  Future<List<VaultItem>> items();

  Future<int> totalBytes();

  /// Number of stored items (cheap – no file-system pruning).
  Future<int> itemCount();

  /// Encrypts [sourcePath] into the vault and deletes the original.
  /// [key] is the operation's [sessionKey]; when omitted the live key is used.
  Future<Result<VaultItem>> addFile(
    String sourcePath, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
    Uint8List? key,
  });

  /// Decrypts [item] to [destinationDir] (default: its original folder, which
  /// is recreated when it no longer exists) and removes it from the vault.
  /// Returns the restored path.
  Future<Result<String>> exportItem(
    VaultItem item, {
    String? destinationDir,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
    Uint8List? key,
  });

  /// Decrypts [item] into a temporary cache file for viewing. The caller
  /// should [clearTemporaryFiles] when done.
  Future<Result<String>> decryptToTemp(
    VaultItem item, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  Future<Result<void>> deleteItem(VaultItem item);

  Future<void> clearTemporaryFiles();
}
