import '../entities/product_entity.dart';

abstract interface class ProductRepository {
  Future<List<ProductEntity>> getAll({required int storeId});
  Future<ProductEntity?> getById(int id);
  Future<void> save(ProductEntity product);
  Future<void> delete(int id);

  Future<List<CategoryEntity>> getAllCategories({required int storeId});
  Future<void> saveCategory(CategoryEntity category);
  Future<void> deleteCategory(int id);
}
