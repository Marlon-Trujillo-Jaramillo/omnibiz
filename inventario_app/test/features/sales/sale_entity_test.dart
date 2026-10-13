import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';

SaleItemEntity _item({int quantity = 1, int unitPrice = 1000}) =>
    SaleItemEntity(
      productId:        1,
      productName:      'Producto',
      quantity:         quantity,
      unitPrice:        unitPrice,
      totalPrice:       unitPrice * quantity,
      selectedVariants: [],
    );

SaleEntity _sale({List<SaleItemEntity>? items}) => SaleEntity(
      id:              1,
      items:           items ?? [_item()],
      totalAmount:     10000,
      taxAmount:       0,
      discountAmount:  0,
      paymentMethod:   'Efectivo',
      businessContext: 'generic',
      createdAt:       DateTime(2024),
      storeId:         0,
      currencyCode:    'COP',
    );

void main() {
  group('SaleEntity.itemCount', () {
    test('un item con quantity 1', () {
      expect(_sale(items: [_item(quantity: 1)]).itemCount, 1);
    });

    test('varios items suman quantidades', () {
      final sale = _sale(items: [
        _item(quantity: 2),
        _item(quantity: 3),
      ]);
      expect(sale.itemCount, 5);
    });

    test('sin items es 0', () {
      expect(_sale(items: []).itemCount, 0);
    });
  });

  group('CartItemEntity.totalPrice', () {
    test('precio total = unitPrice * quantity', () {
      const item = CartItemEntity(
        productId:        1,
        productName:      'Test',
        quantity:         3,
        unitPrice:        5000,
        selectedVariants: [],
      );
      expect(item.totalPrice, 15000);
    });

    test('copyWith modifica quantity', () {
      const item = CartItemEntity(
        productId:        1,
        productName:      'Test',
        quantity:         1,
        unitPrice:        5000,
        selectedVariants: [],
      );
      final copy = item.copyWith(quantity: 5);
      expect(copy.quantity, 5);
      expect(copy.totalPrice, 25000);
    });
  });
}
