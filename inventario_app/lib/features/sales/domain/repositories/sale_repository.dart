import '../entities/sale_entity.dart';

abstract interface class SaleRepository {
  Future<List<SaleEntity>> getAll({required int storeId});
  Future<List<SaleEntity>> getByDateRange(DateTime from, DateTime to, {required int storeId});
  Future<void> save(SaleEntity sale);
  Stream<List<SaleEntity>> watchAll({required int storeId});
}
