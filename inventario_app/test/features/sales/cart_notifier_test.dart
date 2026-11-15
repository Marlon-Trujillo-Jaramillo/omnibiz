import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/features/sales/presentation/providers/cart_notifier.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';

/// Sucursal en memoria (sin almacenamiento seguro).
class _FakeCurrentStore extends CurrentStoreNotifier {
  @override
  int? build() => 1;

  @override
  Future<void> set(int storeId) async => state = storeId;
}

ProductEntity _product() => ProductEntity(
  id: 7,
  name: 'Café',
  category: 'General',
  price: 3000,
  costPrice: 1000,
  stock: 10,
  sku: 'SKU-7',
  variants: const [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  storeId: 1,
);

void main() {
  test(
    'cambiar de sucursal vacía el carrito y el cliente seleccionado',
    () async {
      final c = ProviderContainer(
        overrides: [currentStoreProvider.overrideWith(_FakeCurrentStore.new)],
      );
      addTearDown(c.dispose);

      c.read(cartProvider.notifier)
        ..addProduct(_product())
        ..selectCustomer(3);
      expect(c.read(cartProvider).items, hasLength(1));

      await c.read(currentStoreProvider.notifier).set(2);

      expect(c.read(cartProvider).items, isEmpty);
      expect(c.read(cartProvider).selectedCustomerId, isNull);
    },
  );

  test('re-seleccionar la misma sucursal conserva el carrito', () async {
    final c = ProviderContainer(
      overrides: [currentStoreProvider.overrideWith(_FakeCurrentStore.new)],
    );
    addTearDown(c.dispose);

    c.read(cartProvider.notifier).addProduct(_product());
    await c.read(currentStoreProvider.notifier).set(1);

    expect(c.read(cartProvider).items, hasLength(1));
  });
}
