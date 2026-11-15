class Sale {
  const Sale({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.createdAt,
    required this.paymentMethod,
    required this.businessContext,
    required this.storeId,
    required this.currencyCode,
    this.customerId,
  });

  final int id;
  final List<SaleItem> items;

  /// Centavos.
  final int totalAmount;
  final int taxAmount;
  final int discountAmount;
  final DateTime createdAt;
  final String paymentMethod;
  final int? customerId;
  final String businessContext;
  final int storeId;
  final String currencyCode;

  Map<String, dynamic> toMap() => {
    'items': items.map((i) => i.toMap()).toList(),
    'totalAmount': totalAmount,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'createdAt': createdAt.toIso8601String(),
    'paymentMethod': paymentMethod,
    'customerId': customerId,
    'businessContext': businessContext,
    'storeId': storeId,
    'currencyCode': currencyCode,
  };

  static Sale fromMap(int id, Map<String, dynamic> map) => Sale(
    id: id,
    items: (map['items'] as List)
        .map((i) => SaleItem.fromMap(Map<String, dynamic>.from(i as Map)))
        .toList(),
    totalAmount: map['totalAmount'] as int,
    taxAmount: map['taxAmount'] as int,
    discountAmount: map['discountAmount'] as int,
    createdAt: DateTime.parse(map['createdAt'] as String),
    paymentMethod: map['paymentMethod'] as String,
    customerId: map['customerId'] as int?,
    businessContext: map['businessContext'] as String,
    storeId: map['storeId'] as int? ?? 0,
    // La migración v2 rellena la moneda; COP sólo como red de seguridad.
    currencyCode: map['currencyCode'] as String? ?? 'COP',
  );
}

class SaleItem {
  const SaleItem({
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
  final int totalPrice;
  final List<String> selectedVariants;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
    'selectedVariants': selectedVariants,
  };

  static SaleItem fromMap(Map<String, dynamic> map) => SaleItem(
    productId: map['productId'] as int,
    productName: map['productName'] as String,
    quantity: map['quantity'] as int,
    unitPrice: map['unitPrice'] as int,
    totalPrice: map['totalPrice'] as int,
    selectedVariants: List<String>.from(map['selectedVariants'] as List),
  );
}
