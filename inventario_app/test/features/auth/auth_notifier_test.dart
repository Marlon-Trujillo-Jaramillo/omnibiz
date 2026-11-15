import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/app/router/app_router.dart';
import 'package:inventario_app/core/utils/app_constants.dart';
import 'package:inventario_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:inventario_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inventario_app/features/auth/presentation/screens/splash_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.hasPinResult});

  static const pin = '1234';

  /// Si se da, `hasPin()` devuelve este future (para simular lecturas lentas o fallidas).
  final Future<bool>? hasPinResult;
  PinLockout lockout = PinLockout.none;

  @override
  Future<bool> hasPin() => hasPinResult ?? Future.value(true);
  @override
  Future<void> setPin(String pin) async {}
  @override
  Future<bool> verifyPin(String pin) async => pin == _FakeAuthRepository.pin;
  @override
  Future<void> clearPin() async {}
  @override
  Future<bool> canUseBiometrics() async => false;
  @override
  Future<bool> authenticateWithBiometrics() async => false;
  @override
  Future<PinLockout> readLockout() async => lockout;
  @override
  Future<void> writeLockout(PinLockout l) async => lockout = l;
}

void main() {
  late DateTime now;

  ProviderContainer container(_FakeAuthRepository repo) {
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        authClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle(ProviderContainer c) async {
    c.read(authProvider);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() => now = DateTime(2025, 1, 1, 12));

  group('init falla cerrado', () {
    test(
      'error del almacenamiento → locked (no initial ni authenticated)',
      () async {
        final c = container(
          _FakeAuthRepository(
            hasPinResult: Future.error(Exception('keystore roto')),
          ),
        );
        await settle(c);

        expect(c.read(authProvider).status, AuthStatus.locked);
      },
    );

    test('con PIN → locked', () async {
      final c = container(_FakeAuthRepository());
      await settle(c);

      expect(c.read(authProvider).status, AuthStatus.locked);
    });
  });

  group('bloqueo por intentos', () {
    test(
      'tras maxPinAttempts fallos bloquea incluso el PIN correcto',
      () async {
        final repo = _FakeAuthRepository();
        final c = container(repo);
        await settle(c);
        final auth = c.read(authProvider.notifier);

        for (var i = 0; i < AppConstants.maxPinAttempts; i++) {
          expect(await auth.unlockWithPin('0000'), isFalse);
        }
        expect(repo.lockout.failedAttempts, AppConstants.maxPinAttempts);
        expect(
          c.read(authProvider).lockedUntil,
          now.add(AppConstants.pinLockoutBase),
        );

        expect(await auth.unlockWithPin('1234'), isFalse);
        expect(c.read(authProvider).status, AuthStatus.locked);

        // Pasado el bloqueo, el PIN correcto entra y resetea el contador.
        now = now.add(AppConstants.pinLockoutBase + const Duration(seconds: 1));
        expect(await auth.unlockWithPin('1234'), isTrue);
        expect(c.read(authProvider).status, AuthStatus.authenticated);
        expect(repo.lockout.failedAttempts, 0);
      },
    );

    test('el bloqueo persistido se respeta al reiniciar', () async {
      final repo = _FakeAuthRepository()
        ..lockout = PinLockout(
          failedAttempts: 5,
          lockedUntil: now.add(const Duration(minutes: 1)),
        );
      final c = container(repo);
      await settle(c);

      expect(c.read(authProvider).lockedUntil, isNotNull);
      expect(
        await c.read(authProvider.notifier).unlockWithPin('1234'),
        isFalse,
      );
    });

    test(
      'pinLockoutFor: sin bloqueo antes del máximo, luego exponencial con tope',
      () {
        const max = AppConstants.maxPinAttempts;
        expect(pinLockoutFor(max - 1), Duration.zero);
        expect(pinLockoutFor(max), AppConstants.pinLockoutBase);
        expect(pinLockoutFor(max + 1), AppConstants.pinLockoutBase * 2);
        expect(pinLockoutFor(max + 50), AppConstants.pinLockoutMax);
      },
    );
  });

  test('lock() no bloquea si no hay sesión abierta', () async {
    final c = container(_FakeAuthRepository(hasPinResult: Future.value(false)));
    await settle(c);

    c.read(authProvider.notifier).lock();
    expect(c.read(authProvider).status, AuthStatus.noPinSet);
  });

  testWidgets('router: mientras auth es initial solo se ve el splash', (
    tester,
  ) async {
    final pending = Completer<bool>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(hasPinResult: pending.future),
          ),
        ],
        child: Consumer(
          builder: (_, ref, __) =>
              MaterialApp.router(routerConfig: ref.watch(routerProvider)),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    // Intento de deep-link a una ruta protegida: sigue en splash.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SplashScreen)),
    );
    container.read(routerProvider).go('/dashboard/customers');
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    // El spinner no termina nunca: desmontar para no colgar pumpAndSettle.
    await tester.pumpWidget(const SizedBox());
  });
}
