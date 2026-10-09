import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/data/services/native_vault_crypto.dart';
import 'package:pointycastle/export.dart';

/// AES-256-GCM file encryption for the Secure Folder.
///
/// File format (`.fv`):
/// ```
/// magic "FVLT" | version u8 | chunkSize u32 | noncePrefix[8] | plainSize u64
/// then for every chunk i: ciphertext(chunk) || tag(16)
/// ```
/// Each chunk uses nonce = prefix || i and authenticates the header, the
/// chunk index and a last-chunk flag as associated data, so chunks cannot be
/// reordered, dropped or truncated without detection.
class VaultCryptoService {
  const VaultCryptoService();

  static const List<int> magic = <int>[0x46, 0x56, 0x4C, 0x54]; // FVLT
  static const int version = 1;
  static const int headerLength = 25;
  static const int tagLength = 16;
  static const int keyLength = 32;

  /// Upper bound accepted for a header's chunk size (protects against
  /// corrupt files asking for absurd buffers).
  static const int maxChunkSize = 64 * 1024 * 1024;

  // ------------------------------------------------------------ keys

  static Uint8List randomBytes(int length) {
    final Random rng = Random.secure();
    final Uint8List out = Uint8List(length);
    for (int i = 0; i < length; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }

  /// PBKDF2-HMAC-SHA256. Runs in a worker because 120k rounds take a moment.
  Future<Uint8List> deriveKey(String pin, Uint8List salt, {int iterations = AppConstants.vaultPbkdf2Iterations}) {
    return IsolateWorker.run<List<Object>, Uint8List>(
      <Object>[pin, salt, iterations],
      _deriveJob,
      debugName: 'pbkdf2',
    );
  }

  static Future<Uint8List> _deriveJob(List<Object> args, WorkerContext ctx) async {
    return deriveKeySync(args[0] as String, args[1] as Uint8List, iterations: args[2] as int);
  }

  static Uint8List deriveKeySync(String pin, Uint8List salt, {int iterations = AppConstants.vaultPbkdf2Iterations}) {
    final PBKDF2KeyDerivator derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(pin)));
  }

  /// Single-shot AES-GCM used to wrap the master key: nonce || ct || tag.
  static Uint8List sealBytes(Uint8List key, Uint8List plain, {Uint8List? aad}) {
    final Uint8List nonce = randomBytes(12);
    final GCMBlockCipher cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), tagLength * 8, nonce, aad ?? Uint8List(0)));
    final Uint8List ct = cipher.process(plain);
    return Uint8List.fromList(<int>[...nonce, ...ct]);
  }

  /// Inverse of [sealBytes]. Throws [WrongPasswordFailure] on tag mismatch.
  static Uint8List openBytes(Uint8List key, Uint8List sealed, {Uint8List? aad}) {
    if (sealed.length < 12 + tagLength) throw const WrongPasswordFailure();
    final Uint8List nonce = sealed.sublist(0, 12);
    final Uint8List ct = sealed.sublist(12);
    final GCMBlockCipher cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), tagLength * 8, nonce, aad ?? Uint8List(0)));
    try {
      return cipher.process(ct);
    } on InvalidCipherTextException {
      throw const WrongPasswordFailure();
    } catch (_) {
      throw const WrongPasswordFailure();
    }
  }

  // ----------------------------------------------------------- files

  /// Encrypts [source] into [destination]. Uses the native AES-GCM engine on
  /// Android (an order of magnitude faster, which is what makes large videos
  /// practical) and the pure-Dart engine everywhere else.
  Future<void> encryptFile(
    String source,
    String destination,
    Uint8List key, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final bool native = await NativeVaultCrypto.instance.encryptFile(
      source,
      destination,
      key,
      chunkSize: AppConstants.vaultNativeChunkBytes,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    if (native) return;
    return IsolateWorker.run<List<Object>, void>(
      <Object>[source, destination, key, AppConstants.vaultChunkBytes],
      _encryptJob,
      onProgress: onProgress,
      cancelToken: cancelToken,
      debugName: 'vault-encrypt',
    );
  }

  Future<void> decryptFile(
    String source,
    String destination,
    Uint8List key, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final bool native = await NativeVaultCrypto.instance.decryptFile(
      source,
      destination,
      key,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    if (native) return;
    return IsolateWorker.run<List<Object>, void>(
      <Object>[source, destination, key],
      _decryptJob,
      onProgress: onProgress,
      cancelToken: cancelToken,
      debugName: 'vault-decrypt',
    );
  }

  static Future<void> _encryptJob(List<Object> args, WorkerContext ctx) async {
    final String source = args[0] as String;
    final String destination = args[1] as String;
    final Uint8List key = args[2] as Uint8List;
    final int chunkSize = args[3] as int;
    final File src = File(source);
    final int total = src.lengthSync();
    final Uint8List prefix = randomBytes(8);
    final Uint8List header = _buildHeader(chunkSize, prefix, total);
    final RandomAccessFile input = src.openSync();
    final RandomAccessFile output;
    try {
      output = File(destination).openSync(mode: FileMode.writeOnly);
    } catch (_) {
      _closeQuietly(input);
      rethrow;
    }
    try {
      output.writeFromSync(header);
      final int chunks = total == 0 ? 1 : (total + chunkSize - 1) ~/ chunkSize;
      int done = 0;
      for (int i = 0; i < chunks; i++) {
        final bool last = i == chunks - 1;
        final int want = last ? total - i * chunkSize : chunkSize;
        final Uint8List plain = input.readSync(want);
        if (plain.length != want) {
          throw const IoFailure(message: 'The file changed while it was being encrypted');
        }
        final GCMBlockCipher cipher = GCMBlockCipher(AESEngine())
          ..init(true, AEADParameters(KeyParameter(key), tagLength * 8, _nonce(prefix, i), _aad(header, i, last)));
        output.writeFromSync(cipher.process(plain));
        done += plain.length;
        ctx.report(total == 0 ? 1 : done / total);
        await ctx.checkpoint();
      }
      output.flushSync();
    } catch (_) {
      _closeQuietly(output);
      _closeQuietly(input);
      try {
        File(destination).deleteSync();
      } catch (_) {}
      rethrow;
    }
    _closeQuietly(output);
    _closeQuietly(input);
  }

  static Future<void> _decryptJob(List<Object> args, WorkerContext ctx) async {
    final String source = args[0] as String;
    final String destination = args[1] as String;
    final Uint8List key = args[2] as Uint8List;
    final RandomAccessFile input = File(source).openSync();
    final RandomAccessFile output;
    try {
      output = File(destination).openSync(mode: FileMode.writeOnly);
    } catch (_) {
      _closeQuietly(input);
      rethrow;
    }
    try {
      final Uint8List header = input.readSync(headerLength);
      if (header.length != headerLength ||
          header[0] != magic[0] ||
          header[1] != magic[1] ||
          header[2] != magic[2] ||
          header[3] != magic[3] ||
          header[4] != version) {
        throw const IoFailure(message: 'Not a FileVault encrypted file');
      }
      final ByteData view = ByteData.sublistView(header);
      final int chunkSize = view.getUint32(5);
      if (chunkSize <= 0 || chunkSize > maxChunkSize) {
        throw const IoFailure(message: 'Corrupt FileVault header');
      }
      final Uint8List prefix = header.sublist(9, 17);
      final int total = view.getUint64(17);
      final int chunks = total == 0 ? 1 : (total + chunkSize - 1) ~/ chunkSize;
      int done = 0;
      for (int i = 0; i < chunks; i++) {
        final bool last = i == chunks - 1;
        final int plainLen = last ? total - i * chunkSize : chunkSize;
        final Uint8List ct = input.readSync(plainLen + tagLength);
        if (ct.length != plainLen + tagLength) {
          throw const IoFailure(message: 'Encrypted file is truncated');
        }
        final GCMBlockCipher cipher = GCMBlockCipher(AESEngine())
          ..init(false, AEADParameters(KeyParameter(key), tagLength * 8, _nonce(prefix, i), _aad(header, i, last)));
        final Uint8List plain;
        try {
          plain = cipher.process(ct);
        } on InvalidCipherTextException {
          throw const WrongPasswordFailure(message: 'Integrity check failed');
        }
        output.writeFromSync(plain);
        done += plain.length;
        ctx.report(total == 0 ? 1 : done / total);
        await ctx.checkpoint();
      }
      output.flushSync();
    } catch (_) {
      _closeQuietly(output);
      _closeQuietly(input);
      try {
        File(destination).deleteSync();
      } catch (_) {}
      rethrow;
    }
    _closeQuietly(output);
    _closeQuietly(input);
  }

  /// Closes a handle without letting a failing close mask the real error or
  /// leak the other handle.
  static void _closeQuietly(RandomAccessFile file) {
    try {
      file.closeSync();
    } catch (_) {}
  }

  static Uint8List _buildHeader(int chunkSize, Uint8List prefix, int total) {
    final Uint8List header = Uint8List(headerLength);
    header.setRange(0, 4, magic);
    header[4] = version;
    final ByteData view = ByteData.sublistView(header);
    view.setUint32(5, chunkSize);
    header.setRange(9, 17, prefix);
    view.setUint64(17, total);
    return header;
  }

  static Uint8List _nonce(Uint8List prefix, int index) {
    final Uint8List nonce = Uint8List(12);
    nonce.setRange(0, 8, prefix);
    ByteData.sublistView(nonce).setUint32(8, index);
    return nonce;
  }

  static Uint8List _aad(Uint8List header, int index, bool last) {
    final Uint8List aad = Uint8List(headerLength + 5);
    aad.setRange(0, headerLength, header);
    ByteData.sublistView(aad).setUint32(headerLength, index);
    aad[headerLength + 4] = last ? 1 : 0;
    return aad;
  }
}
