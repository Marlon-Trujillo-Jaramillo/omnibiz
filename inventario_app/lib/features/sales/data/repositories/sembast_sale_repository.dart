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
  // commitSale() toca productos y clientes dentro de la misma transacción.
  static final _products = intMapStoreFactory.store('products');
  static final _customers = intMapStoreFactory.store('customers');

  @override
  Future<List<SaleEntity>> getByDateRange(
    DateTime from,
    DateTime to, {
    required int storeId,
  }) async {
    AppLogger.d(
      _tag,
      'getByDateRange([${from.toIso8601String()}, ${to.toIso8601String()}), storeId=$storeId)',
    );
    // createdAt se guarda como ISO-8601 local: el orden lexicográfico es el
    // cronológico. Intervalo semiabierto [from, to).
    final finder = Finder(
      filter: Filter.and([
        Filter.greaterThanOrEquals('createdAt', from.toIso8601String()),
        Filter.lessThan('createdAt', to.toIso8601String()),
        Filter.equals('storeId', storeId),
      ]),
      sortOrders: [SortOrder('createdAt', false)],
    );
    final snapshots = await _sales.find(_db, finder: finder);
    AppLogger.d(_tag, 'getByDateRange() → ${snapshots.length} ventas');
    return _toEntities(snapshots);
  }

  @override
  Future<List<SaleEntity>> getPage({
    required int storeId,
    required int limit,
    DateTime? before,
    DateTime? from,
    String? paymentMethod,
  }) async {
    AppLogger.d(_tag,
        'getPage(storeId=$storeId, limit=$limit, before=$before, from=$from, method=$paymentMethod)');
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('storeId', storeId),
        if (before != null)
          Filter.lessThan('createdAt', before.toIso8601String()),
        if (from != null)
          Filter.greaterThanOrEquals('createdAt', from.toIso8601String()),
        if (paymentMethod != null)
          Filter.equals('paymentMethod', paymentMethod),
      ]),
      sortOrders: [SortOrder('createdAt', false)],
      limit: limit,
    );
    final snapshots = await _sales.find(_db, finder: finder);
    AppLogger.d(_tag, 'getPage() → ${snapshots.length} ventas');
    return _toEntities(snapshots);
  }

  static List<SaleEntity> _toEntities(
    List<RecordSnapshot<int, Map<String, Object?>>> snapshots,
  ) =>
      snapshots.map((s) => Sale.fromMap(s.key, s.value).toEntity()).toList();

  @override
  Future<SaleEntity> commitSale(SaleEntity entity) async {
    AppLogger.i(
      _tag,
      'commitSale() total=${entity.totalAmount} method=${entity.paymentMethod} items=${entity.items.length}',
    );

    // Cantidad total por producto: dos líneas del mismo producto suman.
    final requested = <int, int>{};
    for (final item in entity.items) {
      requested[item.productId] =
          (requested[item.productId] ?? 0) + item.quantity;
    }

    final newId = await _db.transaction((txn) async {
      // 1. Leer y validar TODO antes de escribir nada.
      final newStocks = <int, int>{};
      for (final MapEntry(key: productId, value: qty) in requested.entries) {
        final name = entity.items
            .firstWhere((i) => i.productId == productId)
            .productName;
        final value = await _products.record(productId).get(txn);
        if (value == null) {
          throw ProductNotFoundRejection('Producto "$name" no encontrado');
        }
        if ((value['storeId'] as int?) != entity.storeId) {
          throw InvalidSaleRejection('"$name" no pertenece a esta sucursal');
        }
        final stock = value['stock'] as int;
        if (stock < qty) {
          throw InsufficientStockRejection(
            'Stock insuficiente para "$name". Disponible: $stock, solicitado: $qty',
          );
        }
        newStocks[productId] = stock - qty;
      }

      Map<String, Object?>? customer;
      if (entity.customerId != null) {
        customer = await _customers.record(entity.customerId!).get(txn);
        if (customer == null) {
          throw const InvalidSaleRejection('El cliente seleccionado no existe');
        }
        if ((customer['storeId'] as int?) != entity.storeId) {
          throw const InvalidSaleRejection(
            'El cliente no pertenece a esta sucursal',
          );
        }
      }

      // 2. Escribir. Cualquier excepción aquí revierte la transacción entera.
      for (final MapEntry(key: productId, value: stock) in newStocks.entries) {
        await _products.record(productId).update(txn, {'stock': stock});
      }
      if (entity.paymentMethod == PaymentMethods.credit && customer != null) {
        final prev = customer['totalDebt'] as int;
        await _customers.record(entity.customerId!).update(txn, {
          'totalDebt': prev + entity.totalAmount,
          'lastTransaction': DateTime.now().toIso8601String(),
        });
      }
      return _sales.add(txn, entity.toModel().toMap());
    });

    AppLogger.i(_tag, 'commitSale() → venta id=$newId ✓');
    return entity.copyWith(id: newId);
  }
}
