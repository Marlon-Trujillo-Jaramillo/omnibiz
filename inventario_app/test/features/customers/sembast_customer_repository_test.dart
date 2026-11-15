import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:inventario_app/features/customers/data/repositories/sembast_customer_repository.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';
import 'package:inventario_app/features/customers/domain/repositories/customer_repository.dart';

int _dbCounter = 0;
String _dbName() => 'customers_${_dbCounter++}.db';

CustomerEntity _entity({int id = 0, String name = 'Ana', int totalDebt = 0}) =>
    CustomerEntity(
      id: id,
      name: name,
      totalDebt: totalDebt,
      createdAt: DateTime(2024),
      storeId: 0,
    );

void main() {
  late SembastCustomerRepository repo;
  late Database db;
  late String dbName;

  setUp(() async {
    dbName = _dbName();
    db = await databaseFactoryMemory.openDatabase(dbName);
    repo = SembastCustomerRepository(db);
  });

  tearDown(() async {
    await db.close();
    await databaseFactoryMemory.deleteDatabase(dbName);
  });

  group('getAll / save', () {
    test('vacío inicialmente', () async {
      expect(await repo.getAll(storeId: 0), isEmpty);
    });

    test('guarda y recupera cliente', () async {
      await repo.save(_entity(name: 'Carlos'));
      final all = await repo.getAll(storeId: 0);
      expect(all, hasLength(1));
      expect(all.first.name, 'Carlos');
    });

    test('ordena alfabéticamente', () async {
      await repo.save(_entity(name: 'Zara'));
      await repo.save(_entity(name: 'Ana'));
      await repo.save(_entity(name: 'Mario'));
      final names = (await repo.getAll(storeId: 0)).map((c) => c.name).toList();
      expect(names, ['Ana', 'Mario', 'Zara']);
    });
  });

  group('getById', () {
    test('retorna null si no existe', () async {
      expect(await repo.getById(999), isNull);
    });

    test('retorna el cliente correcto', () async {
      await repo.save(_entity(name: 'Pedro'));
      final id = (await repo.getAll(storeId: 0)).first.id;
      final found = await repo.getById(id);
      expect(found?.name, 'Pedro');
    });
  });

  group('delete', () {
    test('elimina cliente', () async {
      await repo.save(_entity(name: 'Test'));
      final id = (await repo.getAll(storeId: 0)).first.id;
      await repo.delete(id);
      expect(await repo.getAll(storeId: 0), isEmpty);
    });
  });

  group('registerPayment', () {
    Future<int> withDebt(int debt) async {
      await repo.save(_entity(name: 'Pedro', totalDebt: debt));
      return (await repo.getAll(storeId: 0)).first.id;
    }

    test('abono parcial descuenta la deuda', () async {
      final id = await withDebt(10000);

      await repo.registerPayment(id, 4000);
      expect((await repo.getById(id))?.totalDebt, 6000);
    });

    test(
      'monto mayor que la deuda → InvalidPaymentException sin cambios',
      () async {
        final id = await withDebt(10000);

        await expectLater(
          repo.registerPayment(id, 10001),
          throwsA(isA<InvalidPaymentException>()),
        );
        expect((await repo.getById(id))?.totalDebt, 10000);
      },
    );

    test('monto <= 0 → InvalidPaymentException', () async {
      final id = await withDebt(10000);

      await expectLater(
        repo.registerPayment(id, 0),
        throwsA(isA<InvalidPaymentException>()),
      );
      await expectLater(
        repo.registerPayment(id, -5),
        throwsA(isA<InvalidPaymentException>()),
      );
      expect((await repo.getById(id))?.totalDebt, 10000);
    });

    test('pagar la deuda completa la deja exactamente en 0', () async {
      // 0.10 + 0.20 en centavos: en double quedaría 0.30000000000000004.
      final id = await withDebt(10 + 20);

      await repo.registerPayment(id, 30);
      expect((await repo.getById(id))?.totalDebt, 0);
      expect((await repo.getById(id))?.hasDebt, isFalse);
    });

    test('un centavo de más se rechaza (sin tolerancias)', () async {
      final id = await withDebt(1001);

      await expectLater(
        repo.registerPayment(id, 1002),
        throwsA(isA<InvalidPaymentException>()),
      );
      expect((await repo.getById(id))?.totalDebt, 1001);
    });
  });

  group('delete', () {
    test('elimina un cliente sin deuda', () async {
      await repo.save(_entity(name: 'Ana'));
      final id = (await repo.getAll(storeId: 0)).single.id;
      await repo.delete(id);
      expect(await repo.getById(id), isNull);
    });

    test('un cliente que debe dinero no se elimina', () async {
      await repo.save(_entity(name: 'Ana', totalDebt: 2500));
      final id = (await repo.getAll(storeId: 0)).single.id;
      await expectLater(
        repo.delete(id),
        throwsA(
          isA<CustomerHasDebtException>().having((e) => e.debt, 'debt', 2500),
        ),
      );
      expect((await repo.getById(id))?.totalDebt, 2500);
    });

    test('tras pagar toda la deuda ya se puede eliminar', () async {
      await repo.save(_entity(name: 'Ana', totalDebt: 2500));
      final id = (await repo.getAll(storeId: 0)).single.id;
      await repo.registerPayment(id, 2500);
      await repo.delete(id);
      expect(await repo.getById(id), isNull);
    });
  });
}
