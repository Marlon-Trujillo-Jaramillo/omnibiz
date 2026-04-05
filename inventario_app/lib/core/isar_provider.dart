import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:inventario_app/models/product_model.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Initialize this in main');
});

final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>(
  (ref) {
    final isar = ref.watch(isarProvider);
    return ProductsNotifier(isar);
  },
);

class ProductsNotifier extends StateNotifier<List<Product>> {
  final Isar _isar;

  ProductsNotifier(this._isar) : super([]) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = await _isar.products.where().findAll();
  }

  Future<void> addProduct(Product product) async {
    await _isar.writeTxn(() async {
      await _isar.products.put(product);
    });
    await loadProducts();
  }

  Future<void> updateStock(int productId, int newStock) async {
    final product = await _isar.products.get(productId);
    if (product != null) {
      product.stock = newStock;
      await _isar.writeTxn(() async {
        await _isar.products.put(product);
      });
      await loadProducts();
    }
  }

  Future<void> deleteProduct(int productId) async {
    await _isar.writeTxn(() async {
      await _isar.products.delete(productId);
    });
    await loadProducts();
  }
}
