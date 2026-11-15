import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:inventario_app/core/security/pin_hasher.dart';
import 'package:inventario_app/core/utils/app_constants.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/auth/domain/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
    this.iterations = AppConstants.pinHashIterations,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _localAuth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  /// Iteraciones PBKDF2 para hashes nuevos (configurable para tests).
  final int iterations;

  static const _tag = 'LocalAuthRepo';
  static const _pinKey = 'omni_pin_hash';
  static const _attemptsKey = 'omni_pin_failed_attempts';
  static const _lockedKey = 'omni_pin_locked_until';

  @override
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinKey);
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<void> setPin(String pin) async {
    await _storage.write(
      key: _pinKey,
      value: await PinHasher.hash(pin, iterations: iterations),
    );
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null || stored.isEmpty) return false;
    final ok = await PinHasher.verify(pin, stored);
    // Migración: un PIN correcto guardado en el formato legado (SHA-256 sin
    // sal) o con otras iteraciones se re-guarda en el formato actual.
    if (ok && PinHasher.needsRehash(stored, iterations: iterations)) {
      AppLogger.i(_tag, 'verifyPin() → migrando hash de PIN al formato PBKDF2');
      await setPin(pin);
    }
    return ok;
  }

  @override
  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await writeLockout(PinLockout.none);
  }

  @override
  Future<PinLockout> readLockout() async {
    final attempts = int.tryParse(await _storage.read(key: _attemptsKey) ?? '');
    final until = DateTime.tryParse(await _storage.read(key: _lockedKey) ?? '');
    return PinLockout(failedAttempts: attempts ?? 0, lockedUntil: until);
  }

  @override
  Future<void> writeLockout(PinLockout lockout) async {
    await _storage.write(key: _attemptsKey, value: '${lockout.failedAttempts}');
    if (lockout.lockedUntil == null) {
      await _storage.delete(key: _lockedKey);
    } else {
      await _storage.write(
        key: _lockedKey,
        value: lockout.lockedUntil!.toIso8601String(),
      );
    }
  }

  @override
  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Usa tu huella o Face ID para acceder a OmniBiz',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
