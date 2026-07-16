import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/auth/data/repositories/local_auth_repository.dart';
import 'package:inventario_app/features/auth/domain/repositories/auth_repository.dart';

enum AuthStatus { initial, noPinSet, locked, authenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.hasBiometrics = false,
    this.error,
  });

  final AuthStatus status;
  final bool hasBiometrics;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLocked => status == AuthStatus.locked;
  bool get requiresSetup => status == AuthStatus.noPinSet;

  AuthState copyWith({AuthStatus? status, bool? hasBiometrics, String? error}) {
    return AuthState(
      status:       status       ?? this.status,
      hasBiometrics: hasBiometrics ?? this.hasBiometrics,
      error:        error,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository();
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  static const _tag = 'AuthNotifier';

  Future<void> _init() async {
    AppLogger.i(_tag, '_init(): verificando PIN y biometría...');
    final hasPin = await _repo.hasPin();
    final canBio = await _repo.canUseBiometrics();
    final status = hasPin ? AuthStatus.locked : AuthStatus.noPinSet;
    AppLogger.i(_tag, '_init(): hasPin=$hasPin canBio=$canBio → status=$status');
    state = AuthState(status: status, hasBiometrics: canBio);
  }

  Future<void> setupPin(String pin) async {
    AppLogger.i(_tag, 'setupPin()');
    await _repo.setPin(pin);
    state = state.copyWith(status: AuthStatus.authenticated);
    AppLogger.i(_tag, 'setupPin() → autenticado');
  }

  Future<bool> unlockWithPin(String pin) async {
    AppLogger.i(_tag, 'unlockWithPin()');
    final ok = await _repo.verifyPin(pin);
    if (ok) {
      AppLogger.i(_tag, 'unlockWithPin() → ok ✓');
      state = state.copyWith(status: AuthStatus.authenticated, error: null);
    } else {
      AppLogger.w(_tag, 'unlockWithPin() → PIN incorrecto ✗');
      state = state.copyWith(error: 'PIN incorrecto');
    }
    return ok;
  }

  Future<bool> unlockWithBiometrics() async {
    AppLogger.i(_tag, 'unlockWithBiometrics()');
    final ok = await _repo.authenticateWithBiometrics();
    if (ok) {
      AppLogger.i(_tag, 'unlockWithBiometrics() → ok ✓');
      state = state.copyWith(status: AuthStatus.authenticated, error: null);
    } else {
      AppLogger.w(_tag, 'unlockWithBiometrics() → denegado ✗');
    }
    return ok;
  }

  void lock() {
    AppLogger.i(_tag, 'lock()');
    state = state.copyWith(status: AuthStatus.locked, error: null);
  }

  Future<void> resetPin() async {
    AppLogger.i(_tag, 'resetPin()');
    await _repo.clearPin();
    state = state.copyWith(status: AuthStatus.noPinSet, error: null);
  }
}
