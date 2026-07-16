import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:inventario_app/features/customers/data/repositories/sembast_customer_repository.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';

int _dbCounter = 0;
String _dbName() => 'customers_${_dbCounter++}.db';

CustomerEntity _entity({
  int id = 0,
  String name = 'Ana',
  double totalDebt = 0,
}) =>
    CustomerEntity(
      id:        id,
      name:      name,
      totalDebt: totalDebt,
      createdAt: DateTime(2024),
      storeId:   0,
    );

void main() {
  late SembastCustomerRepository repo;
  late Database db;
  late String dbName;

  setUp(() async {
    dbName = _dbName();
    db     = await databaseFactoryMemory.openDatabase(dbName);
    repo   = SembastCustomerRepository(db);
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

  group('updateDebt', () {
    test('incrementa la deuda', () async {
      await repo.save(_entity(name: 'Luis', totalDebt: 10000));
      final id = (await repo.getAll(storeId: 0)).first.id;

      await repo.updateDebt(id, 5000);
      final updated = await repo.getById(id);
      expect(updated?.totalDebt, 15000);
    });

    test('actualiza lastTransaction', () async {
      await repo.save(_entity(name: 'María'));
      final id = (await repo.getAll(storeId: 0)).first.id;

      await repo.updateDebt(id, 1000);
      final updated = await repo.getById(id);
      expect(updated?.lastTransaction, isNotNull);
    });

    test('no falla con id inexistente', () async {
      await expectLater(repo.updateDebt(999, 1000), completes);
    });
  });
}
