import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:let_note/core/crypto/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    test('Encrypt and decrypt roundtrip with AES-256', () {
      const plainText = 'Confidential lecture notes & financial records.';
      const passphrase = 'SecretPassphrase123!';

      final encrypted = EncryptionService.encryptText(plainText, passphrase);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plainText)));

      final decrypted = EncryptionService.decryptText(encrypted, passphrase);
      expect(decrypted, equals(plainText));
    });

    test('Decryption with incorrect passphrase fails gracefully', () {
      const plainText = 'Top Secret Note';
      const correctPin = '1234';
      const wrongPin = '9999';

      final encrypted = EncryptionService.encryptText(plainText, correctPin);
      expect(
        () => EncryptionService.decryptText(encrypted, wrongPin),
        throwsException,
      );
    });

    test('PBKDF2 PIN hashing produces consistent verification', () {
      const pin = '4321';
      final salt = EncryptionService.generateSalt(16);

      final hash1 = EncryptionService.hashPin(pin, salt);
      final hash2 = EncryptionService.hashPin(pin, salt);

      expect(hash1, equals(hash2));

      final wrongHash = EncryptionService.hashPin('0000', salt);
      expect(wrongHash, isNot(equals(hash1)));
    });

    test('SHA-256 Checksum validation matches for identical data', () {
      final data = utf8.encode('LetNote Backup Payload Test');
      final checksum1 = EncryptionService.calculateChecksum(data);
      final checksum2 = EncryptionService.calculateChecksum(data);

      expect(checksum1, equals(checksum2));
      expect(checksum1.length, equals(64)); // 256-bit hex string
    });
  });
}
