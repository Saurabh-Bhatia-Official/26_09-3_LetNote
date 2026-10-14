abstract class SecurityRepository {
  Future<bool> hasPinSet();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> removePin();

  Future<bool> isBiometricsAvailable();
  Future<bool> isBiometricsEnabled();
  Future<void> setBiometricsEnabled(bool enabled);

  Future<int> getAutoLockTimeoutMinutes();
  Future<void> setAutoLockTimeoutMinutes(int minutes);
}
