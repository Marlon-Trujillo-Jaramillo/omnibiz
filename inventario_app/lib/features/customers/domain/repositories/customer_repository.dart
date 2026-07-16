import '../entities/customer_entity.dart';

abstract interface class CustomerRepository {
  Future<List<CustomerEntity>> getAll({required int storeId});
  Future<CustomerEntity?> getById(int id);
  Future<void> save(CustomerEntity customer);
  Future<void> delete(int id);
  Future<void> updateDebt(int id, double delta);
}
