import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:inventario_app/features/inventory/data/repositories/sembast_product_repository.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';

int _dbCounter = 0;
String _dbName() => 'products_${_dbCounter++}.db';

ProductEntity _entity({
  int id = 0,
  String name = 'Café',
  int stock = 10,
}) =>
    ProductEntity(
      id:        id,
      name:      name,
      category:  'Bebidas',
      price:     3000,
      costPrice: 1500,
      stock:     stock,
      sku:       'SKU-001',
      variants:  [],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      storeId:   0,
    );

void main() {
  late SembastProductRepository repo;
  late Database db;
  late String dbName;

  setUp(() async {
    dbName = _dbName();
    db     = await databaseFactoryMemory.openDatabase(dbName);
    repo   = SembastProductRepository(db);
  });

  tearDown(() async {
    await db.close();
    await databaseFactoryMemory.deleteDatabase(dbName);
  });

  group('getAll / save', () {
    test('vacío inicialmente', () async {
      expect(await repo.getAll(storeId: 0), isEmpty);
    });

    test('guarda y recupera producto nuevo', () async {
      await repo.save(_entity(name: 'Leche'));
      final all = await repo.getAll(storeId: 0);
      expect(all, hasLength(1));
      expect(all.first.name, 'Leche');
    });

    test('actualiza producto existente', () async {
      await repo.save(_entity(id: 0, name: 'Original'));
      final saved = (await repo.getAll(storeId: 0)).first;

      await repo.save(saved.copyWith(name: 'Editado'));
      final all = await repo.getAll(storeId: 0);
      expect(all, hasLength(1));
      expect(all.first.name, 'Editado');
    });
  });

  group('getById', () {
    test('retorna null si no existe', () async {
      expect(await repo.getById(999), isNull);
    });

    test('retorna la entidad correcta', () async {
      await repo.save(_entity(name: 'Chocolate'));
      final id = (await repo.getAll(storeId: 0)).first.id;
      final found = await repo.getById(id);
      expect(found?.name, 'Chocolate');
    });
  });

  group('delete', () {
    test('elimina el producto', () async {
      await repo.save(_entity());
      final id = (await repo.getAll(storeId: 0)).first.id;
      await repo.delete(id);
      expect(await repo.getAll(storeId: 0), isEmpty);
    });
  });

  group('updateStock', () {
    test('actualiza solo el stock', () async {
      await repo.save(_entity(name: 'Arroz', stock: 50));
      final id = (await repo.getAll(storeId: 0)).first.id;
      await repo.updateStock(id, 30);
      final updated = await repo.getById(id);
      expect(updated?.stock, 30);
      expect(updated?.name, 'Arroz');
    });
  });

  group('getByBarcode', () {
    test('retorna null si no hay coincidencia', () async {
      await repo.save(_entity());
      expect(await repo.getByBarcode('999', storeId: 0), isNull);
    });

    test('encuentra por barcode', () async {
      final withBarcode = ProductEntity(
        id:        0,
        name:      'Con barcode',
        category:  'X',
        price:     1000,
        costPrice: 500,
        stock:     5,
        sku:       'SKU-B',
        variants:  [],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        barcode:   '7501234',
        storeId:   0,
      );
      await repo.save(withBarcode);
      final found = await repo.getByBarcode('7501234', storeId: 0);
      expect(found?.name, 'Con barcode');
    });
  });

  group('categorías', () {
    test('guardar y listar', () async {
      const cat = CategoryEntity(id: 0, name: 'Bebidas', icon: 'cup', storeId: 0);
      await repo.saveCategory(cat);
      final all = await repo.getAllCategories(storeId: 0);
      expect(all, hasLength(1));
      expect(all.first.name, 'Bebidas');
    });

    test('eliminar categoría', () async {
      const cat = CategoryEntity(id: 0, name: 'Snacks', icon: 'food', storeId: 0);
      await repo.saveCategory(cat);
      final id = (await repo.getAllCategories(storeId: 0)).first.id;
      await repo.deleteCategory(id);
      expect(await repo.getAllCategories(storeId: 0), isEmpty);
    });
  });
}
