import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/crypto/encryption_service.dart';
import '../../domain/repositories/security_repository.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  final FlutterSecureStorage secureStorage;

  SecurityRepositoryImpl({FlutterSecureStorage? storage})
      : secureStorage = storage ?? const FlutterSecureStorage();

  @override
  Future<bool> hasPinSet() async {
    final hash = await secureStorage.read(key: AppConstants.keyAppPinHash);
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<void> setPin(String pin) async {
    final salt = EncryptionService.generateSalt(16);
    final saltBase64 = base64Encode(salt);
    final hash = EncryptionService.hashPin(pin, salt);

    await secureStorage.write(key: AppConstants.keyAppPinSalt, value: saltBase64);
    await secureStorage.write(key: AppConstants.keyAppPinHash, value: hash);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final storedHash = await secureStorage.read(key: AppConstants.keyAppPinHash);
    final storedSaltBase64 = await secureStorage.read(key: AppConstants.keyAppPinSalt);

    if (storedHash == null || storedSaltBase64 == null) {
      return false;
    }

    final salt = base64Decode(storedSaltBase64);
    final computedHash = EncryptionService.hashPin(pin, salt);
    return storedHash == computedHash;
  }

  @override
  Future<void> removePin() async {
    await secureStorage.delete(key: AppConstants.keyAppPinHash);
    await secureStorage.delete(key: AppConstants.keyAppPinSalt);
    await secureStorage.delete(key: AppConstants.keyBiometricsEnabled);
  }

  @override
  Future<bool> isBiometricsAvailable() async {
    // Basic hardware availability check
    return false; // Can be enhanced with local_auth on supported hardware
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    final val = await secureStorage.read(key: AppConstants.keyBiometricsEnabled);
    return val == 'true';
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    await secureStorage.write(
      key: AppConstants.keyBiometricsEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  @override
  Future<int> getAutoLockTimeoutMinutes() async {
    final val = await secureStorage.read(key: AppConstants.keyAutoLockTimeout);
    if (val == null) return 5; // Default 5 minutes
    return int.tryParse(val) ?? 5;
  }

  @override
  Future<void> setAutoLockTimeoutMinutes(int minutes) async {
    await secureStorage.write(
      key: AppConstants.keyAutoLockTimeout,
      value: minutes.toString(),
    );
  }
}
