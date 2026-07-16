import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';

ProductEntity _product({
  int id = 1,
  String name = 'Café',
  double price = 5000,
  double costPrice = 3000,
  int stock = 10,
}) =>
    ProductEntity(
      id:        id,
      name:      name,
      category:  'Bebidas',
      price:     price,
      costPrice: costPrice,
      stock:     stock,
      sku:       'SKU-001',
      variants:  [],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      storeId:   0,
    );

void main() {
  group('ProductEntity.isLowStock', () {
    test('false cuando stock >= 5', () {
      expect(_product(stock: 5).isLowStock, false);
      expect(_product(stock: 10).isLowStock, false);
    });

    test('true cuando stock < 5', () {
      expect(_product(stock: 4).isLowStock, true);
      expect(_product(stock: 0).isLowStock, true);
    });
  });

  group('ProductEntity.isOutOfStock', () {
    test('false cuando stock > 0', () {
      expect(_product(stock: 1).isOutOfStock, false);
    });

    test('true cuando stock == 0', () {
      expect(_product(stock: 0).isOutOfStock, true);
    });
  });

  group('ProductEntity.margin', () {
    test('margen correcto', () {
      // (5000 - 3000) / 5000 = 0.4
      expect(_product(price: 5000, costPrice: 3000).margin, closeTo(0.4, 0.001));
    });

    test('precio cero retorna 0', () {
      expect(_product(price: 0, costPrice: 0).margin, 0.0);
    });
  });

  group('ProductEntity.profit', () {
    test('ganancia por unidad', () {
      expect(_product(price: 5000, costPrice: 3000).profit, 2000.0);
    });

    test('puede ser negativa', () {
      expect(_product(price: 1000, costPrice: 2000).profit, -1000.0);
    });
  });

  group('ProductEntity.copyWith', () {
    test('modifica solo el campo indicado', () {
      final base     = _product(name: 'Original', stock: 10);
      final modified = base.copyWith(stock: 99);
      expect(modified.stock, 99);
      expect(modified.name, 'Original');
    });
  });

  group('CategoryEntity.copyWith', () {
    test('modifica campo', () {
      const cat  = CategoryEntity(id: 1, name: 'Bebidas', icon: 'coffee', storeId: 0);
      final copy = cat.copyWith(name: 'Comida');
      expect(copy.name, 'Comida');
      expect(copy.icon, 'coffee');
    });
  });
}
