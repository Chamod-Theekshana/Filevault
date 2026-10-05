import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/data/services/vault_crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('fv_vault_test');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  group('VaultCryptoService key wrapping', () {
    test('seals and opens with the same key', () {
      final Uint8List key = VaultCryptoService.randomBytes(32);
      final Uint8List plain = Uint8List.fromList(List<int>.generate(64, (int i) => i));
      final Uint8List sealed = VaultCryptoService.sealBytes(key, plain);
      expect(VaultCryptoService.openBytes(key, sealed), plain);
    });

    test('rejects the wrong key', () {
      final Uint8List key = VaultCryptoService.randomBytes(32);
      final Uint8List other = VaultCryptoService.randomBytes(32);
      final Uint8List sealed =
          VaultCryptoService.sealBytes(key, Uint8List.fromList(<int>[1, 2, 3]));
      expect(
        () => VaultCryptoService.openBytes(other, sealed),
        throwsA(isA<WrongPasswordFailure>()),
      );
    });

    test('derives a stable key from the same PIN and salt', () {
      final Uint8List salt = VaultCryptoService.randomBytes(16);
      final Uint8List a = VaultCryptoService.deriveKeySync('123456', salt, iterations: 1000);
      final Uint8List b = VaultCryptoService.deriveKeySync('123456', salt, iterations: 1000);
      final Uint8List c = VaultCryptoService.deriveKeySync('654321', salt, iterations: 1000);
      expect(a, b);
      expect(a, isNot(c));
      expect(a.length, 32);
    });
  });

  group('VaultCryptoService file round trip', () {
    test('encrypts and decrypts a multi-chunk file byte for byte', () async {
      const VaultCryptoService crypto = VaultCryptoService();
      final Uint8List key = VaultCryptoService.randomBytes(32);
      final Random rng = Random(7);
      final Uint8List payload =
          Uint8List.fromList(List<int>.generate(2 * 1024 * 1024 + 1234, (_) => rng.nextInt(256)));

      final String source = p.join(temp.path, 'secret.bin');
      final String encrypted = p.join(temp.path, 'secret.fv');
      final String restored = p.join(temp.path, 'restored.bin');
      await File(source).writeAsBytes(payload);

      await crypto.encryptFile(source, encrypted, key);
      expect(await File(encrypted).exists(), isTrue);
      expect(await File(encrypted).length(), greaterThan(payload.length));

      await crypto.decryptFile(encrypted, restored, key);
      expect(await File(restored).readAsBytes(), payload);
    });

    test('empty files survive the round trip', () async {
      const VaultCryptoService crypto = VaultCryptoService();
      final Uint8List key = VaultCryptoService.randomBytes(32);
      final String source = p.join(temp.path, 'empty.txt');
      final String encrypted = p.join(temp.path, 'empty.fv');
      final String restored = p.join(temp.path, 'empty.out');
      await File(source).writeAsBytes(<int>[]);

      await crypto.encryptFile(source, encrypted, key);
      await crypto.decryptFile(encrypted, restored, key);
      expect(await File(restored).readAsBytes(), isEmpty);
    });

    test('a tampered ciphertext fails the integrity check', () async {
      const VaultCryptoService crypto = VaultCryptoService();
      final Uint8List key = VaultCryptoService.randomBytes(32);
      final String source = p.join(temp.path, 'note.txt');
      final String encrypted = p.join(temp.path, 'note.fv');
      await File(source).writeAsString('secret contents that must stay private');

      await crypto.encryptFile(source, encrypted, key);
      final Uint8List bytes = await File(encrypted).readAsBytes();
      bytes[VaultCryptoService.headerLength + 2] ^= 0xFF;
      await File(encrypted).writeAsBytes(bytes);

      expect(
        () => crypto.decryptFile(encrypted, p.join(temp.path, 'out.txt'), key),
        throwsA(isA<WrongPasswordFailure>()),
      );
    });
  });
}
