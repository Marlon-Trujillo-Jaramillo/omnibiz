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

  @override
  Future<List<StoreEntity>> getAll() async {
    AppLogger.d(_tag, 'getAll()');
    final finder    = Finder(sortOrders: [SortOrder('createdAt')]);
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
    await _stores.record(id).delete(_db);
    AppLogger.i(_tag, 'delete($id) → ok');
  }

  @override
  Stream<List<StoreEntity>> watchAll() {
    AppLogger.d(_tag, 'watchAll() stream iniciado');
    final query = _stores.query(
      finder: Finder(sortOrders: [SortOrder('createdAt')]),
    );
    return query.onSnapshots(_db).map(
          (snapshots) => snapshots
              .map((s) => Store.fromMap(s.key, s.value).toEntity())
              .toList(),
        );
  }
}
