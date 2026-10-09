import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

/// Bridge to the Kotlin `VaultCryptoChannel`, which encrypts and decrypts
/// Secure Folder files with the platform AES-GCM implementation
/// (hardware-accelerated on every ARMv8 phone).
///
/// It produces byte-for-byte the same `.fv` format as the pure-Dart engine in
/// `VaultCryptoService`, so either side can read what the other wrote. When
/// the native side is unavailable (tests, desktop, very old builds) [run]
/// returns `false` and the caller falls back to Dart.
class NativeVaultCrypto {
  NativeVaultCrypto._();

  static final NativeVaultCrypto instance = NativeVaultCrypto._();

  static const MethodChannel _channel = MethodChannel('com.filevault/crypto');

  final Map<String, ProgressCallback> _listeners = <String, ProgressCallback>{};
  bool _handlerInstalled = false;
  bool _unavailable = false;

  bool get supported => !_unavailable && Platform.isAndroid;

  void _ensureHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method != 'progress') return null;
      final Object? raw = call.arguments;
      if (raw is! Map) return null;
      final String? id = raw['jobId'] as String?;
      final int done = (raw['done'] as num?)?.toInt() ?? 0;
      final int total = (raw['total'] as num?)?.toInt() ?? 0;
      if (id == null) return null;
      _listeners[id]?.call(total <= 0 ? 1 : (done / total).clamp(0.0, 1.0), null);
      return null;
    });
  }

  Future<void> _cancel(String jobId) async {
    try {
      await _channel.invokeMethod<void>('cancel', <String, Object?>{'jobId': jobId});
    } catch (_) {}
  }

  /// Runs [method] natively. Returns `true` when the job completed, `false`
  /// when the native engine is not available. Native errors are mapped to
  /// the app's [Failure] types.
  Future<bool> run(
    String method,
    Map<String, Object?> arguments, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (!supported) return false;
    _ensureHandler();
    cancelToken?.throwIfCancelled();
    final String jobId = const Uuid().v4();
    void onCancel() => unawaited(_cancel(jobId));
    if (onProgress != null) _listeners[jobId] = onProgress;
    cancelToken?.addListener(onCancel);
    try {
      await _channel.invokeMethod<void>(method, <String, Object?>{
        ...arguments,
        'jobId': jobId,
      });
      return true;
    } on MissingPluginException {
      _unavailable = true;
      return false;
    } on PlatformException catch (e) {
      throw switch (e.code) {
        'CANCELLED' => const CancelledFailure(),
        'INTEGRITY' => const WrongPasswordFailure(message: 'Integrity check failed'),
        'FORMAT' => const IoFailure(message: 'Not a FileVault encrypted file'),
        'NOT_FOUND' => NotFoundFailure(message: e.message),
        'NO_SPACE' => DiskFullFailure(message: e.message),
        'PERMISSION' => PermissionFailure(message: e.message),
        _ => IoFailure(message: e.message),
      };
    } finally {
      _listeners.remove(jobId);
      cancelToken?.removeListener(onCancel);
    }
  }

  Future<bool> encryptFile(
    String source,
    String destination,
    Uint8List key, {
    required int chunkSize,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    return run(
      'encryptFile',
      <String, Object?>{
        'source': source,
        'destination': destination,
        'key': key,
        'chunkSize': chunkSize,
      },
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<bool> decryptFile(
    String source,
    String destination,
    Uint8List key, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    return run(
      'decryptFile',
      <String, Object?>{'source': source, 'destination': destination, 'key': key},
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}
