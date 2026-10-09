import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/utils/app_logger.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/data/database/app_database.dart';
import 'package:filevault/data/services/file_system_service.dart';
import 'package:filevault/data/services/vault_crypto_service.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/vault_item.dart';
import 'package:filevault/domain/repositories/vault_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Secure Folder implementation.
///
/// * A random 256-bit master key encrypts every file (chunked AES-GCM).
/// * The master key is wrapped with a key derived from the PIN (PBKDF2).
/// * With biometrics enabled the master key is additionally kept in the
///   Android Keystore-backed secure storage and released after a successful
///   fingerprint/face prompt.
class VaultRepositoryImpl implements VaultRepository {
  VaultRepositoryImpl(
    this._db,
    this._fs,
    this._crypto, {
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secure = secureStorage ?? const FlutterSecureStorage(),
        _auth = localAuth ?? LocalAuthentication();

  final AppDatabase _db;
  final FileSystemService _fs;
  final VaultCryptoService _crypto;
  final FlutterSecureStorage _secure;
  final LocalAuthentication _auth;

  static const String _secureKeyName = 'filevault.vault.master';
  static const String _prefsAttempts = 'vault_failed_attempts';
  static const String _prefsLockedUntil = 'vault_locked_until';
  static const String _metaFile = 'meta.json';

  Uint8List? _masterKey;
  Directory? _dir;

  /// Blobs being written right now. The orphan sweep in [items] must never
  /// touch them (their database row is only inserted once encryption ends).
  final Set<String> _inFlight = <String>{};

  @override
  bool get isUnlocked => _masterKey != null;

  Future<Directory> _vaultDir() async {
    final Directory? cached = _dir;
    if (cached != null) return cached;
    final Directory support = await getApplicationSupportDirectory();
    final Directory dir = Directory(p.join(support.path, AppConstants.vaultFolderName));
    await dir.create(recursive: true);
    // App-private storage is already invisible to the media scanner and to
    // other apps; the marker is a second line of defence on rooted devices
    // and custom ROMs that index more aggressively.
    final File marker = File(p.join(dir.path, '.nomedia'));
    if (!marker.existsSync()) {
      try {
        marker.createSync();
      } catch (_) {}
    }
    _dir = dir;
    return dir;
  }

  Future<File> _meta() async => File(p.join((await _vaultDir()).path, _metaFile));

  @override
  Future<bool> isConfigured() async => (await _meta()).exists();

  // --------------------------------------------------------------- setup

  @override
  Future<Result<void>> setup(String pin) {
    return Result.guard(() async {
      if (await isConfigured()) {
        throw const AlreadyExistsFailure(message: 'Vault already exists');
      }
      final Uint8List salt = VaultCryptoService.randomBytes(16);
      final Uint8List master = VaultCryptoService.randomBytes(VaultCryptoService.keyLength);
      await _writeMeta(pin, salt, master);
      _masterKey = master;
    });
  }

  Future<void> _writeMeta(String pin, Uint8List salt, Uint8List master) async {
    final Uint8List kek = await _crypto.deriveKey(pin, salt);
    final Uint8List wrapped = VaultCryptoService.sealBytes(kek, master);
    final Uint8List verifier =
        VaultCryptoService.sealBytes(master, Uint8List.fromList(utf8.encode('FILEVAULT-OK')));
    final Map<String, Object?> meta = <String, Object?>{
      'version': 1,
      'salt': base64Encode(salt),
      'iterations': AppConstants.vaultPbkdf2Iterations,
      'wrapped': base64Encode(wrapped),
      'verifier': base64Encode(verifier),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    await (await _meta()).writeAsString(jsonEncode(meta), flush: true);
  }

  Future<Map<String, Object?>> _readMeta() async {
    final File f = await _meta();
    if (!await f.exists()) throw const NotFoundFailure(message: 'Vault not set up');
    return jsonDecode(await f.readAsString()) as Map<String, Object?>;
  }

  // -------------------------------------------------------------- unlock

  @override
  Future<Result<void>> unlock(String pin) {
    return Result.guard(() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int lockedUntil = prefs.getInt(_prefsLockedUntil) ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;
      if (lockedUntil > now) {
        throw VaultLockedFailure(secondsRemaining: ((lockedUntil - now) / 1000).ceil());
      }
      final Map<String, Object?> meta = await _readMeta();
      final Uint8List salt = base64Decode(meta['salt']! as String);
      final int iterations = (meta['iterations'] as num?)?.toInt() ?? AppConstants.vaultPbkdf2Iterations;
      final Uint8List kek = await _crypto.deriveKey(pin, salt, iterations: iterations);
      try {
        final Uint8List master =
            VaultCryptoService.openBytes(kek, base64Decode(meta['wrapped']! as String));
        _masterKey = master;
        await prefs.remove(_prefsAttempts);
        await prefs.remove(_prefsLockedUntil);
      } on WrongPasswordFailure {
        final int attempts = (prefs.getInt(_prefsAttempts) ?? 0) + 1;
        if (attempts >= AppConstants.vaultMaxAttempts) {
          await prefs.setInt(
              _prefsLockedUntil, now + AppConstants.vaultCooldownSeconds * 1000);
          await prefs.remove(_prefsAttempts);
          throw const VaultLockedFailure(secondsRemaining: AppConstants.vaultCooldownSeconds);
        }
        await prefs.setInt(_prefsAttempts, attempts);
        throw WrongPinFailure(attemptsLeft: AppConstants.vaultMaxAttempts - attempts);
      }
    });
  }

  @override
  Future<bool> biometricsAvailable() async {
    try {
      final bool supported = await _auth.isDeviceSupported();
      final bool canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return false;
      final List<BiometricType> types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Result<void>> unlockWithBiometrics() {
    return Result.guard(() async {
      final String? stored = await _secure.read(key: _secureKeyName);
      if (stored == null) throw const NotFoundFailure(message: 'Biometric key not enrolled');
      final bool ok = await _auth.authenticate(
        localizedReason: 'Unlock your Secure Folder',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!ok) throw const PermissionFailure(message: 'Biometric prompt dismissed');
      final Uint8List master = base64Decode(stored);
      final Map<String, Object?> meta = await _readMeta();
      // Validate the key against the verifier before trusting it.
      VaultCryptoService.openBytes(master, base64Decode(meta['verifier']! as String));
      _masterKey = master;
    });
  }

  @override
  Future<Result<void>> setBiometricEnabled(bool enabled) {
    return Result.guard(() async {
      if (!enabled) {
        await _secure.delete(key: _secureKeyName);
        return;
      }
      final Uint8List? master = _masterKey;
      if (master == null) throw const VaultLockedFailure(secondsRemaining: 0);
      await _secure.write(key: _secureKeyName, value: base64Encode(master));
    });
  }

  @override
  Future<Result<void>> changePin(String currentPin, String newPin) {
    return Result.guard(() async {
      final Result<void> check = await unlock(currentPin);
      final Failure? failure = check.failureOrNull;
      if (failure != null) throw failure;
      final Uint8List master = _masterKey!;
      final Uint8List salt = VaultCryptoService.randomBytes(16);
      await _writeMeta(newPin, salt, master);
    });
  }

  @override
  Uint8List? sessionKey() {
    final Uint8List? key = _masterKey;
    return key == null ? null : Uint8List.fromList(key);
  }

  @override
  void lock() {
    final Uint8List? key = _masterKey;
    if (key != null) key.fillRange(0, key.length, 0);
    _masterKey = null;
  }

  @override
  Future<Result<void>> reset() {
    return Result.guard(() async {
      lock();
      final Directory dir = await _vaultDir();
      if (await dir.exists()) await dir.delete(recursive: true);
      _dir = null;
      await _db.db.delete('vault_items');
      await _secure.delete(key: _secureKeyName);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsAttempts);
      await prefs.remove(_prefsLockedUntil);
      await clearTemporaryFiles();
    });
  }

  // --------------------------------------------------------------- items

  @override
  Future<List<VaultItem>> items() async {
    final List<Map<String, Object?>> rows =
        await _db.db.query('vault_items', orderBy: 'added_at DESC');
    final Directory dir = await _vaultDir();
    final List<VaultItem> out = <VaultItem>[];
    final Set<String> known = <String>{};
    for (final Map<String, Object?> row in rows) {
      final VaultItem item = VaultItem.fromRow(row);
      // Prune records whose encrypted blob no longer exists.
      if (_fs.existsSync(p.join(dir.path, item.storedName))) {
        out.add(item);
        known.add(item.storedName);
      } else {
        await _db.db.delete('vault_items', where: 'id = ?', whereArgs: <Object?>[item.id]);
      }
    }
    // ...and blobs whose record is gone, so a failed export cannot leak space.
    // A transfer may finish while this method is suspended above, so the
    // candidates are re-checked against a *fresh* query and the in-flight set
    // synchronously right before anything is deleted.
    final List<File> candidates = <File>[];
    try {
      for (final FileSystemEntity e in dir.listSync(followLinks: false)) {
        final String name = p.basename(e.path);
        if (e is File &&
            (name.endsWith('.fv.part') || (name.endsWith('.fv') && !known.contains(name)))) {
          candidates.add(e);
        }
      }
    } catch (_) {}
    if (candidates.isEmpty) return out;
    final List<Map<String, Object?>> fresh =
        await _db.db.query('vault_items', columns: <String>['stored_name']);
    final Set<String> recorded = <String>{
      for (final Map<String, Object?> row in fresh) row['stored_name']! as String,
    };
    for (final File file in candidates) {
      final String name = p.basename(file.path);
      final String stored = name.endsWith('.part') ? name.substring(0, name.length - 5) : name;
      if (_inFlight.contains(stored) || recorded.contains(name)) continue;
      try {
        file.deleteSync();
      } catch (_) {}
    }
    return out;
  }

  @override
  Future<int> itemCount() async {
    final List<Map<String, Object?>> rows =
        await _db.db.rawQuery('SELECT COUNT(*) AS n FROM vault_items');
    return (rows.first['n'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> totalBytes() async {
    final List<Map<String, Object?>> rows =
        await _db.db.rawQuery('SELECT COALESCE(SUM(size), 0) AS total FROM vault_items');
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  Uint8List _requireKey([Uint8List? provided]) {
    final Uint8List? key = provided ?? _masterKey;
    if (key == null) throw const VaultLockedFailure(secondsRemaining: 0);
    return key;
  }

  @override
  Future<Result<VaultItem>> addFile(
    String sourcePath, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
    Uint8List? key,
  }) {
    return Result.guard(() async {
      final Uint8List masterKey = _requireKey(key);
      final FileEntry entry = await _fs.stat(sourcePath);
      if (entry.isDirectory) {
        throw const IoFailure(message: 'Folders cannot be added to the vault yet');
      }
      final String storedName = '${const Uuid().v4()}.fv';
      final String target = p.join((await _vaultDir()).path, storedName);
      // Write to a ".part" file and rename only when complete, so neither a
      // crash nor the orphan sweep can ever see a half-written blob.
      final String partial = '$target.part';
      _inFlight.add(storedName);
      try {
        await _crypto.encryptFile(sourcePath, partial, masterKey,
            onProgress: onProgress, cancelToken: cancelToken);
        await File(partial).rename(target);
      } catch (_) {
        _inFlight.remove(storedName);
        try {
          final File leftover = File(partial);
          if (leftover.existsSync()) leftover.deleteSync();
        } catch (_) {}
        rethrow;
      }
      // Record first, then remove the plaintext. If either step fails the
      // whole addition is rolled back, so a file is never lost: the original
      // survives on failure and the vault never holds an orphan blob.
      final int id;
      try {
        id = await _db.db.insert('vault_items', <String, Object?>{
          'name': entry.name,
          'original_path': sourcePath,
          'stored_name': storedName,
          'size': entry.size,
          'mime_type': entry.mimeType,
          'category': entry.category.name,
          'added_at': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (_) {
        _inFlight.remove(storedName);
        try {
          await _fs.deleteEntity(target);
        } catch (_) {}
        rethrow;
      }
      _inFlight.remove(storedName);
      try {
        await _fs.deleteEntity(sourcePath);
      } catch (_) {
        await _db.db.delete('vault_items', where: 'id = ?', whereArgs: <Object?>[id]);
        try {
          await _fs.deleteEntity(target);
        } catch (_) {}
        rethrow;
      }
      return VaultItem(
        id: id,
        name: entry.name,
        originalPath: sourcePath,
        storedName: storedName,
        size: entry.size,
        category: entry.category,
        addedAt: DateTime.now(),
        mimeType: entry.mimeType,
      );
    });
  }

  @override
  Future<Result<String>> exportItem(
    VaultItem item, {
    String? destinationDir,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
    Uint8List? key,
  }) {
    return Result.guard(() async {
      final Uint8List masterKey = _requireKey(key);
      String dir = destinationDir ?? p.dirname(item.originalPath);
      // Restore into the original folder, recreating it when it was removed
      // in the meantime; fall back to Downloads when that is impossible
      // (e.g. the SD card it lived on is gone).
      try {
        await Directory(dir).create(recursive: true);
      } catch (_) {
        dir = p.join(AppConstants.primaryStoragePath, AppConstants.downloadsFolder);
        await Directory(dir).create(recursive: true);
      }
      final String target = FileUtils.uniquePathSync(p.join(dir, item.name));
      final String source = p.join((await _vaultDir()).path, item.storedName);
      await _crypto.decryptFile(source, target, masterKey,
          onProgress: onProgress, cancelToken: cancelToken);
      // Drop the record before the blob so a failure never leaves a listed
      // item whose ciphertext is already gone.
      await _db.db.delete('vault_items', where: 'id = ?', whereArgs: <Object?>[item.id]);
      await _fs.deleteEntity(source);
      return target;
    });
  }

  @override
  Future<Result<String>> decryptToTemp(
    VaultItem item, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    return Result.guard(() async {
      final Uint8List key = _requireKey();
      final Directory tmp = await _tempDir();
      // One sub-folder per item keeps the real file name, so viewers and
      // other apps show "holiday.mp4" rather than an internal id.
      final Directory holder = Directory(p.join(tmp.path, '${item.id}'));
      await holder.create(recursive: true);
      final String target = p.join(holder.path, item.name);
      if (File(target).existsSync() && File(target).lengthSync() == item.size) return target;
      final String source = p.join((await _vaultDir()).path, item.storedName);
      await _crypto.decryptFile(source, target, key,
          onProgress: onProgress, cancelToken: cancelToken);
      return target;
    });
  }

  @override
  Future<Result<void>> deleteItem(VaultItem item) {
    return Result.guard(() async {
      final String source = p.join((await _vaultDir()).path, item.storedName);
      await _fs.deleteEntity(source);
      await _db.db.delete('vault_items', where: 'id = ?', whereArgs: <Object?>[item.id]);
    });
  }

  Future<Directory> _tempDir() async {
    final Directory cache = await getTemporaryDirectory();
    final Directory dir = Directory(p.join(cache.path, 'vault_view'));
    await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<void> clearTemporaryFiles() async {
    try {
      final Directory dir = await _tempDir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      appLogger.d('clearTemporaryFiles: $e');
    }
  }
}
