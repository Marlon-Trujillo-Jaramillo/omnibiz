/// Métodos de pago soportados. Se persisten como texto en la venta.
abstract final class PaymentMethods {
  static const cash   = 'Efectivo';
  static const card   = 'Tarjeta';
  /// Venta a crédito: exige cliente y suma el total a su deuda.
  static const credit = 'Fiado';

  static const all = [cash, card, credit];
}

class CartItemEntity {
  const CartItemEntity({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.selectedVariants,
  });

  final int productId;
  final String productName;
  final int quantity;
  /// Centavos (ver `Money`).
  final int unitPrice;
  final List<String> selectedVariants;

  /// Centavos.
  int get totalPrice => unitPrice * quantity;

  CartItemEntity copyWith({int? quantity}) {
    return CartItemEntity(
      productId:        productId,
      productName:      productName,
      quantity:         quantity ?? this.quantity,
      unitPrice:        unitPrice,
      selectedVariants: selectedVariants,
    );
  }
}

class SaleEntity {
  const SaleEntity({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.paymentMethod,
    required this.businessContext,
    required this.createdAt,
    required this.storeId,
    required this.currencyCode,
    this.customerId,
  });

  final int id;
  final List<SaleItemEntity> items;
  /// Montos en centavos (ver `Money`), en la moneda [currencyCode].
  final int totalAmount;
  final int taxAmount;
  final int discountAmount;
  final String paymentMethod;
  final String businessContext;
  final DateTime createdAt;
  final int storeId;
  /// Código ISO de la moneda con la que se registró la venta (`AppCurrency.code`).
  /// Cambiar la moneda en ajustes no reetiqueta ventas ya hechas.
  final String currencyCode;
  final int? customerId;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  SaleEntity copyWith({
    int? id,
    List<SaleItemEntity>? items,
    int? totalAmount,
  }) {
    return SaleEntity(
      id:              id          ?? this.id,
      items:           items       ?? this.items,
      totalAmount:     totalAmount ?? this.totalAmount,
      taxAmount:       taxAmount,
      discountAmount:  discountAmount,
      paymentMethod:   paymentMethod,
      businessContext: businessContext,
      createdAt:       createdAt,
      storeId:         storeId,
      currencyCode:    currencyCode,
      customerId:      customerId,
    );
  }
}

class SaleItemEntity {
  const SaleItemEntity({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.selectedVariants,
  });

  final int productId;
  final String productName;
  final int quantity;
  /// Centavos.
  final int unitPrice;
  /// Centavos.
  final int totalPrice;
  final List<String> selectedVariants;
}
