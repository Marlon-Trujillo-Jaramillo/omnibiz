import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:inventario_app/features/stores/data/repositories/sembast_store_repository.dart';
import 'package:inventario_app/features/stores/domain/entities/store_entity.dart';
import 'package:inventario_app/features/stores/domain/repositories/store_repository.dart';

int _dbCounter = 0;

void main() {
  late Database db;
  late String dbName;
  late SembastStoreRepository repo;
  late int storeId;

  setUp(() async {
    dbName = 'stores_${_dbCounter++}.db';
    db = await databaseFactoryMemory.openDatabase(dbName);
    repo = SembastStoreRepository(db);
    await repo.save(
      StoreEntity(
        id: 0,
        name: 'Centro',
        icon: 'store',
        createdAt: DateTime(2024),
      ),
    );
    storeId = (await repo.getAll()).single.id;
  });

  tearDown(() async {
    await db.close();
    await databaseFactoryMemory.deleteDatabase(dbName);
  });

  Future<void> addRecord(String store, {int? forStore}) =>
      intMapStoreFactory.store(store).add(db, {'storeId': forStore ?? storeId});

  test('sucursal vacía se elimina junto con sus categorías', () async {
    await addRecord('categories');
    await addRecord('categories', forStore: 99);

    await repo.delete(storeId);

    expect(await repo.getAll(), isEmpty);
    final categories = await intMapStoreFactory.store('categories').find(db);
    expect(categories.single.value['storeId'], 99);
  });

  for (final data in ['products', 'sales', 'customers']) {
    test('con $data → StoreInUseException y no se elimina', () async {
      await addRecord(data);

      await expectLater(
        repo.delete(storeId),
        throwsA(
          isA<StoreInUseException>().having(
            (e) => e.message,
            'message',
            contains('No se puede eliminar'),
          ),
        ),
      );
      expect(await repo.getAll(), hasLength(1));
    });
  }

  test('datos de otra sucursal no bloquean', () async {
    await addRecord('products', forStore: 99);

    await repo.delete(storeId);
    expect(await repo.getAll(), isEmpty);
  });
}
