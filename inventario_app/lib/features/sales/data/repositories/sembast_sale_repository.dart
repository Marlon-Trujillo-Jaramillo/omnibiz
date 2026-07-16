import 'package:sembast/sembast.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/sales/data/mappers/sale_mapper.dart';
import 'package:inventario_app/features/sales/data/models/sale_model.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/domain/repositories/sale_repository.dart';

const _tag = 'SaleRepo';

class SembastSaleRepository implements SaleRepository {
  SembastSaleRepository(this._db);

  final Database _db;
  static final _sales = intMapStoreFactory.store('sales');

  @override
  Future<List<SaleEntity>> getAll({required int storeId}) async {
    AppLogger.d(_tag, 'getAll(storeId=$storeId)');
    final finder = Finder(
      filter: Filter.equals('storeId', storeId),
      sortOrders: [SortOrder('createdAt', false)],
    );
    final snapshots = await _sales.find(_db, finder: finder);
    AppLogger.d(_tag, 'getAll() → ${snapshots.length} ventas');
    return snapshots
        .map((s) => Sale.fromMap(s.key, s.value).toEntity())
        .toList();
  }

  @override
  Future<List<SaleEntity>> getByDateRange(DateTime from, DateTime to, {required int storeId}) async {
    AppLogger.d(_tag, 'getByDateRange(${from.toIso8601String()} → ${to.toIso8601String()}, storeId=$storeId)');
    final finder = Finder(
      filter: Filter.and([
        Filter.greaterThanOrEquals('createdAt', from.toIso8601String()),
        Filter.lessThanOrEquals('createdAt', to.toIso8601String()),
        Filter.equals('storeId', storeId),
      ]),
      sortOrders: [SortOrder('createdAt', false)],
    );
    final snapshots = await _sales.find(_db, finder: finder);
    AppLogger.d(_tag, 'getByDateRange() → ${snapshots.length} ventas');
    return snapshots
        .map((s) => Sale.fromMap(s.key, s.value).toEntity())
        .toList();
  }

  @override
  Future<void> save(SaleEntity entity) async {
    AppLogger.i(_tag,
        'save() total=${entity.totalAmount} method=${entity.paymentMethod} items=${entity.items.length}');
    final map = entity.toModel().toMap();
    try {
      await _db.transaction((txn) async {
        if (entity.id == 0) {
          final newId = await _sales.add(txn, map);
          AppLogger.i(_tag, 'save() → nueva venta id=$newId');
        } else {
          await _sales.record(entity.id).put(txn, map);
          AppLogger.i(_tag, 'save() → venta actualizada id=${entity.id}');
        }
      });
    } catch (e, st) {
      AppLogger.e(_tag, 'save() falló', e, st);
      rethrow;
    }
  }

  @override
  Stream<List<SaleEntity>> watchAll({required int storeId}) {
    AppLogger.d(_tag, 'watchAll(storeId=$storeId) stream iniciado');
    final query = _sales.query(
      finder: Finder(
        filter: Filter.equals('storeId', storeId),
        sortOrders: [SortOrder('createdAt', false)],
      ),
    );
    return query.onSnapshots(_db).map(
          (snapshots) => snapshots
              .map((s) => Sale.fromMap(s.key, s.value).toEntity())
              .toList(),
        );
  }
}
