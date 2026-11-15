import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast/utils/sembast_import_export.dart';
import 'package:inventario_app/core/backup/backup_codec.dart';
import 'package:inventario_app/core/backup/backup_service.dart';
import 'package:inventario_app/core/database/money_migration.dart';

const codec = BackupCodec(iterations: 1000);
const password = 'clave-de-respaldo';
final _stores = intMapStoreFactory.store('stores');
final _products = intMapStoreFactory.store('products');
final _customers = intMapStoreFactory.store('customers');

int _counter = 0;

Future<Database> _openDb() => databaseFactoryMemory.openDatabase(
  'backup_${_counter++}.db',
  version: appDbVersion,
);

/// Teléfono "viejo": una sucursal, un producto y un cliente que debe dinero.
Future<Database> _phoneWithData() async {
  final db = await _openDb();
  final storeId = await _stores.add(db, {
    'name': 'Tienda Centro',
    'createdAt': '2026-01-01T00:00:00.000',
  });
  await _products.add(db, {
    'name': 'Café',
    'price': 450000,
    'storeId': storeId,
  });
  await _customers.add(db, {
    'name': 'Ana',
    'totalDebt': 2500,
    'storeId': storeId,
  });
  return db;
}

void main() {
  test('restaurar reemplaza todos los datos del teléfono nuevo', () async {
    final oldPhone = await _phoneWithData();
    final bytes = await BackupService(oldPhone, codec: codec).create(password);

    final newPhone = await _openDb();
    await _products.add(newPhone, {'name': 'Dato que debe desaparecer'});

    final summary = await BackupService(
      newPhone,
      codec: codec,
    ).restore(bytes, password, legacyCurrencyCode: 'COP');

    expect(summary.count('products'), 1);
    expect(summary.count('customers'), 1);
    final products = await _products.find(newPhone);
    expect(products.single.value['name'], 'Café');
    expect(products.single.value['price'], 450000);
    final ana = (await _customers.find(newPhone)).single.value;
    expect(ana['totalDebt'], 2500);
    expect(summary.defaultStoreId, (await _stores.find(newPhone)).single.key);
  });

  test('contraseña incorrecta: los datos actuales no se tocan', () async {
    final bytes = await BackupService(
      await _phoneWithData(),
      codec: codec,
    ).create(password);
    final phone = await _openDb();
    await _products.add(phone, {'name': 'Se queda'});

    await expectLater(
      BackupService(
        phone,
        codec: codec,
      ).restore(bytes, 'otra-clave-123', legacyCurrencyCode: 'COP'),
      throwsA(isA<BackupWrongPasswordException>()),
    );
    expect((await _products.find(phone)).single.value['name'], 'Se queda');
  });

  test(
    'un respaldo del esquema v1 (montos en double) se migra a centavos',
    () async {
      final legacy = await databaseFactoryMemory.openDatabase(
        'legacy_${_counter++}.db',
        version: 1,
      );
      await _products.add(legacy, {
        'name': 'Pan',
        'price': 1.5,
        'costPrice': 0.8,
      });
      await _customers.add(legacy, {'name': 'Luis', 'totalDebt': 12.25});
      final export = await exportDatabase(legacy);
      final bytes = await codec.encode(export, password, schemaVersion: 1);

      final phone = await _openDb();
      await BackupService(
        phone,
        codec: codec,
      ).restore(bytes, password, legacyCurrencyCode: 'COP');

      final pan = (await _products.find(phone)).single.value;
      expect(pan['price'], 150);
      expect(pan['costPrice'], 80);
      expect(
        pan['storeId'],
        isNotNull,
        reason: 'se asigna a la sucursal creada',
      );
      expect((await _customers.find(phone)).single.value['totalDebt'], 1225);
    },
  );

  test('un respaldo de una versión más nueva de la app se rechaza', () async {
    final future = await databaseFactoryMemory.openDatabase(
      'future_${_counter++}.db',
      version: appDbVersion + 1,
    );
    final bytes = await codec.encode(await exportDatabase(future), password);
    final phone = await _openDb();
    await _products.add(phone, {'name': 'Se queda'});

    await expectLater(
      BackupService(
        phone,
        codec: codec,
      ).restore(bytes, password, legacyCurrencyCode: 'COP'),
      throwsA(isA<BackupTooNewException>()),
    );
    expect(await _products.count(phone), 1);
  });
}
