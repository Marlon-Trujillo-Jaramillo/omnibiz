import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/core/utils/app_constants.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/auth/data/repositories/local_auth_repository.dart';
import 'package:inventario_app/features/auth/domain/repositories/auth_repository.dart';

enum AuthStatus { initial, noPinSet, locked, authenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.hasBiometrics = false,
    this.error,
    this.lockedUntil,
  });

  final AuthStatus status;
  final bool hasBiometrics;
  final String? error;
  /// Fin del bloqueo por demasiados intentos fallidos de PIN.
  final DateTime? lockedUntil;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLocked => status == AuthStatus.locked;
  bool get requiresSetup => status == AuthStatus.noPinSet;

  AuthState copyWith({
    AuthStatus? status,
    bool? hasBiometrics,
    String? error,
    DateTime? lockedUntil,
  }) {
    return AuthState(
      status:        status        ?? this.status,
      hasBiometrics: hasBiometrics ?? this.hasBiometrics,
      error:         error,
      lockedUntil:   lockedUntil,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository();
});

/// Reloj inyectable (tests de bloqueo).
final authClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Duración del bloqueo tras [failedAttempts] fallos: nada hasta
/// [AppConstants.maxPinAttempts]; luego base × 2^(extra), con tope.
Duration pinLockoutFor(int failedAttempts) {
  final extra = failedAttempts - AppConstants.maxPinAttempts;
  if (extra < 0) return Duration.zero;
  final factor = 1 << extra.clamp(0, 20);
  final d = AppConstants.pinLockoutBase * factor;
  return d > AppConstants.pinLockoutMax ? AppConstants.pinLockoutMax : d;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  DateTime _now() => ref.read(authClockProvider)();

  static const _tag = 'AuthNotifier';

  /// Falla cerrado: cualquier error leyendo el almacenamiento deja la app
  /// bloqueada en vez de en estado `initial` (que el router no deja pasar).
  Future<void> _init() async {
    AppLogger.i(_tag, '_init(): verificando PIN y biometría...');
    try {
      final hasPin  = await _repo.hasPin();
      final canBio  = await _repo.canUseBiometrics();
      final lockout = await _repo.readLockout();
      final status  = hasPin ? AuthStatus.locked : AuthStatus.noPinSet;
      AppLogger.i(_tag, '_init(): hasPin=$hasPin canBio=$canBio → status=$status');
      state = AuthState(
        status:        status,
        hasBiometrics: canBio,
        lockedUntil:   lockout.isLockedAt(_now()) ? lockout.lockedUntil : null,
      );
    } catch (e, st) {
      AppLogger.e(_tag, '_init() falló → bloqueado por seguridad', e, st);
      state = const AuthState(status: AuthStatus.locked);
    }
  }

  Future<void> setupPin(String pin) async {
    AppLogger.i(_tag, 'setupPin()');
    await _repo.setPin(pin);
    await _repo.writeLockout(PinLockout.none);
    state = state.copyWith(status: AuthStatus.authenticated);
    AppLogger.i(_tag, 'setupPin() → autenticado');
  }

  Future<bool> unlockWithPin(String pin) async {
    AppLogger.i(_tag, 'unlockWithPin()');
    try {
      final lockout = await _repo.readLockout();
      if (lockout.isLockedAt(_now())) {
        AppLogger.w(_tag, 'unlockWithPin() → bloqueado hasta ${lockout.lockedUntil}');
        state = state.copyWith(
            error: 'Demasiados intentos', lockedUntil: lockout.lockedUntil);
        return false;
      }

      if (await _repo.verifyPin(pin)) {
        AppLogger.i(_tag, 'unlockWithPin() → ok ✓');
        await _repo.writeLockout(PinLockout.none);
        state = state.copyWith(status: AuthStatus.authenticated);
        return true;
      }

      final attempts = lockout.failedAttempts + 1;
      final wait     = pinLockoutFor(attempts);
      final until    = wait == Duration.zero ? null : _now().add(wait);
      await _repo.writeLockout(
          PinLockout(failedAttempts: attempts, lockedUntil: until));
      AppLogger.w(_tag, 'unlockWithPin() → PIN incorrecto ✗ (intento $attempts)');
      state = state.copyWith(error: 'PIN incorrecto', lockedUntil: until);
      return false;
    } catch (e, st) {
      AppLogger.e(_tag, 'unlockWithPin() falló', e, st);
      state = state.copyWith(error: 'No se pudo verificar el PIN');
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    AppLogger.i(_tag, 'unlockWithBiometrics()');
    final ok = await _repo.authenticateWithBiometrics();
    if (ok) {
      AppLogger.i(_tag, 'unlockWithBiometrics() → ok ✓');
      // La biometría la garantiza el SO: también levanta el bloqueo por PIN.
      try {
        await _repo.writeLockout(PinLockout.none);
      } catch (e, st) {
        AppLogger.e(_tag, 'unlockWithBiometrics(): no se pudo limpiar bloqueo', e, st);
      }
      state = state.copyWith(status: AuthStatus.authenticated);
    } else {
      AppLogger.w(_tag, 'unlockWithBiometrics() → denegado ✗');
    }
    return ok;
  }

  void lock() {
    // Solo una sesión abierta se bloquea (sin PIN no habría cómo desbloquear).
    if (state.status != AuthStatus.authenticated) return;
    AppLogger.i(_tag, 'lock()');
    state = state.copyWith(status: AuthStatus.locked, lockedUntil: state.lockedUntil);
  }

  Future<void> resetPin() async {
    AppLogger.i(_tag, 'resetPin()');
    await _repo.clearPin();
    state = state.copyWith(status: AuthStatus.noPinSet);
  }
}
