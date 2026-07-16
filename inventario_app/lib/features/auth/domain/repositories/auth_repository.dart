abstract interface class AuthRepository {
  Future<bool> hasPin();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> clearPin();
  Future<bool> canUseBiometrics();
  Future<bool> authenticateWithBiometrics();
}
