import '../entities/product_entity.dart';

abstract interface class ProductRepository {
  Future<List<ProductEntity>> getAll({required int storeId});
  Future<ProductEntity?> getById(int id);
  Future<ProductEntity?> getByBarcode(String barcode, {required int storeId});
  Future<ProductEntity?> getBySku(String sku, {required int storeId});
  Future<void> save(ProductEntity product);
  Future<void> delete(int id);
  Future<void> updateStock(int id, int newStock);
  Stream<List<ProductEntity>> watchAll({required int storeId});

  Future<List<CategoryEntity>> getAllCategories({required int storeId});
  Future<void> saveCategory(CategoryEntity category);
  Future<void> deleteCategory(int id);
}
