class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.sku,
    required this.variants,
    required this.createdAt,
    required this.updatedAt,
    required this.storeId,
    this.barcode,
  });

  final int id;
  final String name;
  final String category;

  /// Centavos.
  final int price;

  /// Centavos.
  final int costPrice;
  final int stock;
  final String sku;
  final String? barcode;
  final List<String> variants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int storeId;

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'price': price,
    'costPrice': costPrice,
    'stock': stock,
    'sku': sku,
    'barcode': barcode,
    'variants': variants,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'storeId': storeId,
  };

  static Product fromMap(int id, Map<String, dynamic> map) => Product(
    id: id,
    name: map['name'] as String,
    category: map['category'] as String,
    price: map['price'] as int,
    costPrice: map['costPrice'] as int,
    stock: map['stock'] as int,
    sku: map['sku'] as String,
    barcode: map['barcode'] as String?,
    variants: List<String>.from(map['variants'] as List),
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    storeId: map['storeId'] as int? ?? 0,
  );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.storeId,
  });

  final int id;
  final String name;
  final String icon;
  final int storeId;

  Map<String, dynamic> toMap() => {
    'name': name,
    'icon': icon,
    'storeId': storeId,
  };

  static Category fromMap(int id, Map<String, dynamic> map) => Category(
    id: id,
    name: map['name'] as String,
    icon: map['icon'] as String,
    storeId: map['storeId'] as int? ?? 0,
  );
}
