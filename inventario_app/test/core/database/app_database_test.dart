import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';
import 'package:inventario_app/core/database/app_database.dart';
import 'package:inventario_app/core/database/database_encryption.dart';
import 'package:inventario_app/core/database/money_migration.dart';

final _products = intMapStoreFactory.store('products');
final _stores = intMapStoreFactory.store('stores');

List<int> _key(int seed) => List.generate(32, (i) => (i * 7 + seed) % 256);

void main() {
  late Directory dir;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('omnibiz_db_test');
  });

  tearDown(() async => dir.delete(recursive: true));

  AppDatabaseOpener opener() =>
      AppDatabaseOpener(directory: dir.path, legacyCurrencyCode: 'COP');

  group('codec AES-GCM', () {
    test('roundtrip y el archivo no contiene texto plano', () async {
      final path = p.join(dir.path, 'c.db');
      var db = await databaseFactoryIo.openDatabase(
        path,
        codec: aesGcmSembastCodec(_key(1)),
      );
      await _products.add(db, {'name': 'SecretoCafé', 'price': 1234});
      await db.close();

      final raw = await File(path).readAsString();
      expect(raw, isNot(contains('SecretoCafé')));
      expect(raw, isNot(contains('1234')));

      db = await databaseFactoryIo.openDatabase(
        path,
        codec: aesGcmSembastCodec(_key(1)),
      );
      expect((await _products.record(1).get(db))!['name'], 'SecretoCafé');
      await db.close();
    });

    test(
      'nonce aleatorio: el mismo contenido cifra distinto y descifra igual',
      () async {
        final codec =
            aesGcmSembastCodec(_key(1)).codec! as AsyncContentCodecBase;
        final value = {'name': 'x', 'price': 1};
        final a = await codec.encodeAsync(value);
        final b = await codec.encodeAsync(value);
        expect(a, isNot(b));
        expect(await codec.decodeAsync(a), value);
        expect(await codec.decodeAsync(b), value);
      },
    );

    test('clave incorrecta → invalidCodec', () async {
      final path = p.join(dir.path, 'w.db');
      final db = await databaseFactoryIo.openDatabase(
        path,
        codec: aesGcmSembastCodec(_key(1)),
      );
      await _products.add(db, {'name': 'x'});
      await db.close();
      await expectLater(
        databaseFactoryIo.openDatabase(
          path,
          codec: aesGcmSembastCodec(_key(2)),
        ),
        throwsA(
          isA<DatabaseException>().having(
            (e) => e.code,
            'code',
            DatabaseException.errInvalidCodec,
          ),
        ),
      );
    });
  });

  group('AppDatabaseOpener', () {
    test(
      'instalación nueva: crea clave y BD cifrada en la versión actual',
      () async {
        final result = await opener().open();
        final db = (result as AppDatabaseReady).db;
        expect(db.version, appDbVersion);
        await db.close();
        expect(File(opener().encryptedPath).existsSync(), isTrue);
        expect(await const DatabaseKeyStore().read(), hasLength(32));
      },
    );

    test(
      'migra la BD en texto plano: copia, verifica, borra el plano y convierte montos',
      () async {
        final plain = await databaseFactoryIo.openDatabase(
          opener().plainPath,
          version: 1,
        );
        for (var i = 0; i < 25; i++) {
          await _products.add(plain, {
            'name': 'Producto-secreto-$i',
            'price': 9.99,
            'costPrice': 1.0,
          });
        }
        await _stores.add(plain, {'name': 'Sucursal'});
        await plain.close();

        final db = ((await opener().open()) as AppDatabaseReady).db;
        expect(await _products.count(db), 25);
        expect(await _stores.count(db), 1);
        expect((await _products.record(1).get(db))!['price'], 999);
        expect(db.version, appDbVersion);
        await db.close();

        expect(File(opener().plainPath).existsSync(), isFalse);
        expect(File('${opener().encryptedPath}.tmp').existsSync(), isFalse);
        expect(
          await File(opener().encryptedPath).readAsString(),
          isNot(contains('Producto-secreto')),
        );

        // Segundo arranque: abre la cifrada sin re-migrar.
        final again = ((await opener().open()) as AppDatabaseReady).db;
        expect((await _products.record(1).get(again))!['price'], 999);
        await again.close();
      },
    );

    test(
      'restos de migración interrumpida (plano + cifrada verificada) → borra el plano',
      () async {
        final db = ((await opener().open()) as AppDatabaseReady).db;
        await _stores.add(db, {'name': 'Real'});
        await db.close();
        final stale = await databaseFactoryIo.openDatabase(opener().plainPath);
        await _stores.add(stale, {'name': 'Viejo'});
        await stale.close();

        final reopened = ((await opener().open()) as AppDatabaseReady).db;
        expect((await _stores.find(reopened)).single.value['name'], 'Real');
        await reopened.close();
        expect(File(opener().plainPath).existsSync(), isFalse);
      },
    );

    test(
      'clave perdida → Locked, sin tocar ni sobrescribir el archivo',
      () async {
        final db = ((await opener().open()) as AppDatabaseReady).db;
        await _stores.add(db, {'name': 'Datos'});
        await db.close();
        final before = await File(opener().encryptedPath).readAsBytes();

        FlutterSecureStorage.setMockInitialValues(
          {},
        ); // almacenamiento seguro borrado
        expect(await opener().open(), isA<AppDatabaseLocked>());
        expect(await File(opener().encryptedPath).readAsBytes(), before);
        expect(
          await const DatabaseKeyStore().read(),
          isNull,
        ); // no generó otra clave
      },
    );

    test('clave distinta → Locked', () async {
      final db = ((await opener().open()) as AppDatabaseReady).db;
      await db.close();
      FlutterSecureStorage.setMockInitialValues({
        'omni_db_key_v1': base64.encode(_key(9)),
      });
      expect(await opener().open(), isA<AppDatabaseLocked>());
    });

    test('resetUnreadable aparta el archivo y abre una BD vacía', () async {
      final db = ((await opener().open()) as AppDatabaseReady).db;
      await _stores.add(db, {'name': 'Datos'});
      await db.close();
      FlutterSecureStorage.setMockInitialValues({});

      final fresh = ((await opener().resetUnreadable()) as AppDatabaseReady).db;
      expect(await _stores.count(fresh), 0);
      await fresh.close();
      final backups = dir.listSync().where(
        (f) => f.path.contains('.unreadable-'),
      );
      expect(backups, hasLength(1));
    });
  });
}
