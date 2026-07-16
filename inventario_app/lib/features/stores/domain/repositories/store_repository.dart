import '../entities/store_entity.dart';

abstract interface class StoreRepository {
  Future<List<StoreEntity>> getAll();
  Future<StoreEntity?> getById(int id);
  Future<void> save(StoreEntity store);
  Future<void> delete(int id);
  Stream<List<StoreEntity>> watchAll();
}
