import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import '../errors/failures.dart';

class EncryptionService {
  /// Derive a 256-bit key from a user passphrase/PIN and a salt using PBKDF2-HMAC-SHA256
  static Uint8List deriveKey(String passphrase, List<int> salt, {int iterations = 10000}) {
    final keyBytes = utf8.encode(passphrase);
    var hmac = crypto.Hmac(crypto.sha256, keyBytes);

    // Initial block
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    var result = List<int>.from(u);

    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int k = 0; k < result.length; k++) {
        result[k] ^= u[k];
      }
    }

    return Uint8List.fromList(result);
  }

  /// Generate a cryptographically secure random salt of given length
  static Uint8List generateSalt([int length = 16]) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  /// Hash a PIN using PBKDF2-SHA256 with salt
  static String hashPin(String pin, Uint8List salt) {
    final key = deriveKey(pin, salt, iterations: 10000);
    return base64Encode(key);
  }

  /// Encrypt plaintext with AES-256 using key derived from passphrase
  static String encryptText(String plainText, String passphrase, [Uint8List? customSalt]) {
    try {
      final salt = customSalt ?? generateSalt(16);
      final keyBytes = deriveKey(passphrase, salt);
      final key = enc.Key(keyBytes);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Store salt (16 bytes) + IV (16 bytes) + ciphertext
      final payload = <int>[
        ...salt,
        ...iv.bytes,
        ...encrypted.bytes,
      ];
      return base64Encode(payload);
    } catch (e) {
      throw CryptoFailure('Encryption failed', e);
    }
  }

  /// Decrypt ciphertext with AES-256 using key derived from passphrase
  static String decryptText(String encodedPayload, String passphrase) {
    try {
      final rawBytes = base64Decode(encodedPayload);
      if (rawBytes.length < 32) {
        throw const CryptoFailure('Invalid encrypted payload format');
      }

      final salt = rawBytes.sublist(0, 16);
      final ivBytes = rawBytes.sublist(16, 32);
      final cipherBytes = rawBytes.sublist(32);

      final keyBytes = deriveKey(passphrase, salt);
      final key = enc.Key(keyBytes);
      final iv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final decrypted = encrypter.decrypt(enc.Encrypted(cipherBytes), iv: iv);
      return decrypted;
    } catch (e) {
      throw CryptoFailure('Decryption failed. Incorrect PIN or corrupted data.', e);
    }
  }

  /// Calculate SHA-256 checksum of data for backups and integrity checks
  static String calculateChecksum(List<int> bytes) {
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }
}
