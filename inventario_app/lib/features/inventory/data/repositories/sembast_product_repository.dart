import 'package:sembast/sembast.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/inventory/data/mappers/product_mapper.dart';
import 'package:inventario_app/features/inventory/data/models/product_model.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/features/inventory/domain/repositories/product_repository.dart';

const _tag = 'ProductRepo';

class SembastProductRepository implements ProductRepository {
  SembastProductRepository(this._db);

  final Database _db;
  static final _products   = intMapStoreFactory.store('products');
  static final _categories = intMapStoreFactory.store('categories');

  @override
  Future<List<ProductEntity>> getAll({required int storeId}) async {
    AppLogger.d(_tag, 'getAll(storeId=$storeId)');
    final finder = Finder(filter: Filter.equals('storeId', storeId));
    final snapshots = await _products.find(_db, finder: finder);
    AppLogger.d(_tag, 'getAll() → ${snapshots.length} productos');
    return snapshots
        .map((s) => Product.fromMap(s.key, s.value).toEntity())
        .toList();
  }

  @override
  Future<ProductEntity?> getById(int id) async {
    AppLogger.d(_tag, 'getById($id)');
    final value = await _products.record(id).get(_db);
    if (value == null) {
      AppLogger.w(_tag, 'getById($id) → no encontrado');
      return null;
    }
    return Product.fromMap(id, value).toEntity();
  }

  @override
  Future<void> save(ProductEntity entity) async {
    final isNew = entity.id == 0;
    AppLogger.i(_tag, 'save() name="${entity.name}" id=${entity.id} isNew=$isNew');
    final map = entity.toModel().toMap();
    try {
      await _db.transaction((txn) async {
        if (isNew) {
          final newId = await _products.add(txn, map);
          AppLogger.i(_tag, 'save() → nuevo id=$newId');
        } else {
          await _products.record(entity.id).put(txn, map);
          AppLogger.i(_tag, 'save() → actualizado id=${entity.id}');
        }
      });
    } catch (e, st) {
      AppLogger.e(_tag, 'save() falló para "${entity.name}"', e, st);
      rethrow;
    }
  }

  @override
  Future<void> delete(int id) async {
    AppLogger.i(_tag, 'delete($id)');
    try {
      await _products.record(id).delete(_db);
      AppLogger.i(_tag, 'delete($id) → ok');
    } catch (e, st) {
      AppLogger.e(_tag, 'delete($id) falló', e, st);
      rethrow;
    }
  }

  @override
  Future<List<CategoryEntity>> getAllCategories({required int storeId}) async {
    AppLogger.d(_tag, 'getAllCategories(storeId=$storeId)');
    final finder = Finder(filter: Filter.equals('storeId', storeId));
    final snapshots = await _categories.find(_db, finder: finder);
    AppLogger.d(_tag, 'getAllCategories() → ${snapshots.length} categorías');
    return snapshots
        .map((s) => Category.fromMap(s.key, s.value).toEntity())
        .toList();
  }

  @override
  Future<void> saveCategory(CategoryEntity entity) async {
    final isNew = entity.id == 0;
    AppLogger.i(_tag, 'saveCategory() name="${entity.name}" isNew=$isNew');
    final map = entity.toModel().toMap();
    try {
      await _db.transaction((txn) async {
        if (isNew) {
          final newId = await _categories.add(txn, map);
          AppLogger.i(_tag, 'saveCategory() → nuevo id=$newId');
        } else {
          await _categories.record(entity.id).put(txn, map);
          AppLogger.i(_tag, 'saveCategory() → actualizado id=${entity.id}');
        }
      });
    } catch (e, st) {
      AppLogger.e(_tag, 'saveCategory() falló para "${entity.name}"', e, st);
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    AppLogger.i(_tag, 'deleteCategory($id)');
    await _categories.record(id).delete(_db);
    AppLogger.i(_tag, 'deleteCategory($id) → ok');
  }
}
