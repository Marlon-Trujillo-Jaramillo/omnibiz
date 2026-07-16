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
    this.customerId,
  });

  final int id;
  final List<SaleItem> items;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final DateTime createdAt;
  final String paymentMethod;
  final int? customerId;
  final String businessContext;
  final int storeId;

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
      };

  static Sale fromMap(int id, Map<String, dynamic> map) => Sale(
        id: id,
        items: (map['items'] as List)
            .map((i) => SaleItem.fromMap(Map<String, dynamic>.from(i as Map)))
            .toList(),
        totalAmount: (map['totalAmount'] as num).toDouble(),
        taxAmount: (map['taxAmount'] as num).toDouble(),
        discountAmount: (map['discountAmount'] as num).toDouble(),
        createdAt: DateTime.parse(map['createdAt'] as String),
        paymentMethod: map['paymentMethod'] as String,
        customerId: map['customerId'] as int?,
        businessContext: map['businessContext'] as String,
        storeId: map['storeId'] as int? ?? 0,
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
  final double unitPrice;
  final double totalPrice;
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
        unitPrice: (map['unitPrice'] as num).toDouble(),
        totalPrice: (map['totalPrice'] as num).toDouble(),
        selectedVariants: List<String>.from(map['selectedVariants'] as List),
      );
}
