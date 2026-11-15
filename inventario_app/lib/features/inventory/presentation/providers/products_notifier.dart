import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';
import 'package:inventario_app/shared/providers/database_provider.dart';

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<ProductEntity>>(
      ProductsNotifier.new,
    );

class ProductsNotifier extends AsyncNotifier<List<ProductEntity>> {
  static const _tag = 'ProductsNotifier';

  @override
  Future<List<ProductEntity>> build() {
    final storeId = ref.watch(currentStoreProvider);
    AppLogger.d(_tag, 'build() → cargando productos storeId=$storeId');
    if (storeId == null) return Future.value(const []);
    return ref.watch(productRepositoryProvider).getAll(storeId: storeId);
  }

  Future<void> add(ProductEntity product) async {
    AppLogger.i(_tag, 'add() "${product.name}"');
    try {
      await ref.read(productRepositoryProvider).save(product);
      ref.invalidateSelf();
      AppLogger.i(_tag, 'add() → ok');
    } catch (e, st) {
      AppLogger.e(_tag, 'add() falló', e, st);
      rethrow;
    }
  }

  Future<void> edit(ProductEntity product) async {
    AppLogger.i(_tag, 'edit() id=${product.id} "${product.name}"');
    try {
      await ref.read(productRepositoryProvider).save(product);
      ref.invalidateSelf();
      AppLogger.i(_tag, 'edit() → ok');
    } catch (e, st) {
      AppLogger.e(_tag, 'edit() falló', e, st);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    AppLogger.i(_tag, 'delete($id)');
    try {
      await ref.read(productRepositoryProvider).delete(id);
      ref.invalidateSelf();
      AppLogger.i(_tag, 'delete($id) → ok');
    } catch (e, st) {
      AppLogger.e(_tag, 'delete($id) falló', e, st);
      rethrow;
    }
  }
}

// ── Categories ─────────────────────────────────────────────────────────────────
final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryEntity>>(
      CategoriesNotifier.new,
    );

class CategoriesNotifier extends AsyncNotifier<List<CategoryEntity>> {
  @override
  Future<List<CategoryEntity>> build() {
    final storeId = ref.watch(currentStoreProvider);
    if (storeId == null) return Future.value(const []);
    return ref
        .watch(productRepositoryProvider)
        .getAllCategories(storeId: storeId);
  }

  Future<void> add(CategoryEntity category) async {
    await ref.read(productRepositoryProvider).saveCategory(category);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await ref.read(productRepositoryProvider).deleteCategory(id);
    ref.invalidateSelf();
  }
}
