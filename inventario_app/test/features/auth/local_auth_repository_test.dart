import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/features/auth/data/repositories/local_auth_repository.dart';
import 'package:inventario_app/features/auth/domain/repositories/auth_repository.dart';

const _pinKey = 'omni_pin_hash';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterSecureStorage storage;
  late LocalAuthRepository repo;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    repo = LocalAuthRepository(storage: storage, iterations: 1000);
  });

  test('setPin guarda PBKDF2 con sal, nunca el SHA-256 plano', () async {
    await repo.setPin('1234');

    final stored = await storage.read(key: _pinKey);
    expect(stored, startsWith(r'pbkdf2_sha256$1000$'));
    expect(await repo.verifyPin('1234'), isTrue);
    expect(await repo.verifyPin('9999'), isFalse);
  });

  test('migra un PIN legado (SHA-256 sin sal) al verificarlo', () async {
    final legacy = sha256.convert(utf8.encode('1234')).toString();
    await storage.write(key: _pinKey, value: legacy);

    expect(await repo.verifyPin('1234'), isTrue);

    final migrated = await storage.read(key: _pinKey);
    expect(migrated, startsWith(r'pbkdf2_sha256$'));
    expect(await repo.verifyPin('1234'), isTrue);
  });

  test('un PIN legado incorrecto no migra', () async {
    final legacy = sha256.convert(utf8.encode('1234')).toString();
    await storage.write(key: _pinKey, value: legacy);

    expect(await repo.verifyPin('0000'), isFalse);
    expect(await storage.read(key: _pinKey), legacy);
  });

  test('bloqueo persiste y clearPin lo limpia', () async {
    final until = DateTime(2030, 1, 1, 12);
    await repo.writeLockout(PinLockout(failedAttempts: 6, lockedUntil: until));

    final read = await repo.readLockout();
    expect(read.failedAttempts, 6);
    expect(read.lockedUntil, until);

    await repo.clearPin();
    final cleared = await repo.readLockout();
    expect(cleared.failedAttempts, 0);
    expect(cleared.lockedUntil, isNull);
  });
}
