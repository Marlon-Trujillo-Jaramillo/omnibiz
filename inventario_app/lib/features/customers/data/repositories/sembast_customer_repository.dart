import 'package:sembast/sembast.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/customers/data/mappers/customer_mapper.dart';
import 'package:inventario_app/features/customers/data/models/customer_model.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';
import 'package:inventario_app/features/customers/domain/repositories/customer_repository.dart';

const _tag = 'CustomerRepo';

class SembastCustomerRepository implements CustomerRepository {
  SembastCustomerRepository(this._db);

  final Database _db;
  static final _customers = intMapStoreFactory.store('customers');

  @override
  Future<List<CustomerEntity>> getAll({required int storeId}) async {
    AppLogger.d(_tag, 'getAll(storeId=$storeId)');
    final finder = Finder(
      filter: Filter.equals('storeId', storeId),
      sortOrders: [SortOrder('name')],
    );
    final snapshots = await _customers.find(_db, finder: finder);
    AppLogger.d(_tag, 'getAll() → ${snapshots.length} clientes');
    return snapshots
        .map((s) => Customer.fromMap(s.key, s.value).toEntity())
        .toList();
  }

  @override
  Future<CustomerEntity?> getById(int id) async {
    AppLogger.d(_tag, 'getById($id)');
    final value = await _customers.record(id).get(_db);
    if (value == null) {
      AppLogger.w(_tag, 'getById($id) → no encontrado');
      return null;
    }
    return Customer.fromMap(id, value).toEntity();
  }

  @override
  Future<void> save(CustomerEntity entity) async {
    final isNew = entity.id == 0;
    AppLogger.i(_tag, 'save() name="${entity.name}" isNew=$isNew');
    final map = entity.toModel().toMap();
    try {
      await _db.transaction((txn) async {
        if (isNew) {
          final newId = await _customers.add(txn, map);
          AppLogger.i(_tag, 'save() → nuevo id=$newId');
        } else {
          await _customers.record(entity.id).put(txn, map);
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
    await _db.transaction((txn) async {
      final value = await _customers.record(id).get(txn);
      if (value == null) return;
      final debt = value['totalDebt'] as int;
      if (debt > 0) throw CustomerHasDebtException(debt);
      await _customers.record(id).delete(txn);
    });
    AppLogger.i(_tag, 'delete($id) → ok');
  }

  @override
  Future<void> registerPayment(int id, int amount) async {
    AppLogger.i(_tag, 'registerPayment(id=$id, amount=$amount)');
    if (amount <= 0) {
      throw const InvalidPaymentException('El monto debe ser mayor a cero');
    }
    await _db.transaction((txn) async {
      final value = await _customers.record(id).get(txn);
      if (value == null) {
        throw const InvalidPaymentException('Cliente no encontrado');
      }
      // Centavos enteros: comparación y resta exactas, sin tolerancias.
      final debt = value['totalDebt'] as int;
      if (amount > debt) {
        throw const InvalidPaymentException(
          'El monto supera la deuda del cliente',
        );
      }
      final newDebt = debt - amount;
      AppLogger.i(_tag, 'registerPayment($id): $debt - $amount = $newDebt');
      await _customers.record(id).update(txn, {
        'totalDebt': newDebt,
        'lastTransaction': DateTime.now().toIso8601String(),
      });
    });
  }
}
