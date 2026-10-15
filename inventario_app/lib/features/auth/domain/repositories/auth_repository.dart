abstract interface class AuthRepository {
  Future<bool> hasPin();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> clearPin();
  Future<bool> canUseBiometrics();
  Future<bool> authenticateWithBiometrics();

  /// Intentos fallidos y bloqueo persistidos (sobreviven a reiniciar la app).
  Future<PinLockout> readLockout();
  Future<void> writeLockout(PinLockout lockout);
}

class PinLockout {
  const PinLockout({this.failedAttempts = 0, this.lockedUntil});

  static const none = PinLockout();

  final int failedAttempts;
  final DateTime? lockedUntil;

  bool isLockedAt(DateTime now) =>
      lockedUntil != null && lockedUntil!.isAfter(now);
}
