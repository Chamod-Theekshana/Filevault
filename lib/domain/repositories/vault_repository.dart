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

  /// Permanently destroys the vault and every file in it.
  Future<Result<void>> reset();

  Future<List<VaultItem>> items();

  Future<int> totalBytes();

  /// Encrypts [sourcePath] into the vault and deletes the original.
  Future<Result<VaultItem>> addFile(
    String sourcePath, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  /// Decrypts [item] to [destinationDir] (default: original folder) and
  /// removes it from the vault. Returns the restored path.
  Future<Result<String>> exportItem(
    VaultItem item, {
    String? destinationDir,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
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
