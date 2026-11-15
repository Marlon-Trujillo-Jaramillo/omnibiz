import 'package:sembast/sembast.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/stores/data/mappers/store_mapper.dart';
import 'package:inventario_app/features/stores/data/models/store_model.dart';
import 'package:inventario_app/features/stores/domain/entities/store_entity.dart';
import 'package:inventario_app/features/stores/domain/repositories/store_repository.dart';

const _tag = 'StoreRepo';

class SembastStoreRepository implements StoreRepository {
  SembastStoreRepository(this._db);

  final Database _db;
  static final _stores = intMapStoreFactory.store('stores');
  // delete() verifica / limpia los datos de la sucursal en la misma transacción.
  static final _products = intMapStoreFactory.store('products');
  static final _categories = intMapStoreFactory.store('categories');
  static final _sales = intMapStoreFactory.store('sales');
  static final _customers = intMapStoreFactory.store('customers');

  @override
  Future<List<StoreEntity>> getAll() async {
    AppLogger.d(_tag, 'getAll()');
    final finder = Finder(sortOrders: [SortOrder('createdAt')]);
    final snapshots = await _stores.find(_db, finder: finder);
    AppLogger.d(_tag, 'getAll() → ${snapshots.length} sucursales');
    return snapshots
        .map((s) => Store.fromMap(s.key, s.value).toEntity())
        .toList();
  }

  @override
  Future<StoreEntity?> getById(int id) async {
    AppLogger.d(_tag, 'getById($id)');
    final value = await _stores.record(id).get(_db);
    if (value == null) {
      AppLogger.w(_tag, 'getById($id) → no encontrada');
      return null;
    }
    return Store.fromMap(id, value).toEntity();
  }

  @override
  Future<void> save(StoreEntity entity) async {
    final isNew = entity.id == 0;
    AppLogger.i(_tag, 'save() name="${entity.name}" isNew=$isNew');
    final map = entity.toModel().toMap();
    try {
      await _db.transaction((txn) async {
        if (isNew) {
          final newId = await _stores.add(txn, map);
          AppLogger.i(_tag, 'save() → nueva id=$newId');
        } else {
          await _stores.record(entity.id).put(txn, map);
          AppLogger.i(_tag, 'save() → actualizada id=${entity.id}');
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
    await _db.transaction((txn) async {
      final byStore = Filter.equals('storeId', id);
      final products = await _products.count(txn, filter: byStore);
      final sales = await _sales.count(txn, filter: byStore);
      final customers = await _customers.count(txn, filter: byStore);
      if (products + sales + customers > 0) {
        AppLogger.w(
          _tag,
          'delete($id) → bloqueado: $products productos, $sales ventas, $customers clientes',
        );
        throw StoreInUseException(
          products: products,
          sales: sales,
          customers: customers,
        );
      }
      await _categories.delete(txn, finder: Finder(filter: byStore));
      await _stores.record(id).delete(txn);
    });
    AppLogger.i(_tag, 'delete($id) → ok');
  }

  @override
  Stream<List<StoreEntity>> watchAll() {
    AppLogger.d(_tag, 'watchAll() stream iniciado');
    final query = _stores.query(
      finder: Finder(sortOrders: [SortOrder('createdAt')]),
    );
    return query
        .onSnapshots(_db)
        .map(
          (snapshots) => snapshots
              .map((s) => Store.fromMap(s.key, s.value).toEntity())
              .toList(),
        );
  }
}
