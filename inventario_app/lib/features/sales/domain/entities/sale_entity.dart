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
  final double unitPrice;
  final List<String> selectedVariants;

  double get totalPrice => unitPrice * quantity;

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
    this.customerId,
  });

  final int id;
  final List<SaleItemEntity> items;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final String paymentMethod;
  final String businessContext;
  final DateTime createdAt;
  final int storeId;
  final int? customerId;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
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
  final double unitPrice;
  final double totalPrice;
  final List<String> selectedVariants;
}
