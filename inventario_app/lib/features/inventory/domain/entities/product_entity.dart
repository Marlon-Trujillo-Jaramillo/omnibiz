class ProductEntity {
  const ProductEntity({
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
  final double price;
  final double costPrice;
  final int stock;
  final String sku;
  final List<String> variants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int storeId;
  final String? barcode;

  bool get isLowStock => stock < 5;
  bool get isOutOfStock => stock == 0;
  double get margin => price > 0 ? (price - costPrice) / price : 0;
  double get profit => price - costPrice;

  ProductEntity copyWith({
    int? id, String? name, String? category, double? price, double? costPrice,
    int? stock, String? sku, List<String>? variants, DateTime? createdAt,
    DateTime? updatedAt, int? storeId, String? barcode,
  }) {
    return ProductEntity(
      id:         id         ?? this.id,
      name:       name       ?? this.name,
      category:   category   ?? this.category,
      price:      price      ?? this.price,
      costPrice:  costPrice  ?? this.costPrice,
      stock:      stock      ?? this.stock,
      sku:        sku        ?? this.sku,
      variants:   variants   ?? this.variants,
      createdAt:  createdAt  ?? this.createdAt,
      updatedAt:  updatedAt  ?? this.updatedAt,
      storeId:    storeId    ?? this.storeId,
      barcode:    barcode    ?? this.barcode,
    );
  }
}

class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.storeId,
  });

  final int id;
  final String name;
  final String icon;
  final int storeId;

  CategoryEntity copyWith({int? id, String? name, String? icon, int? storeId}) {
    return CategoryEntity(
      id:      id      ?? this.id,
      name:    name    ?? this.name,
      icon:    icon    ?? this.icon,
      storeId: storeId ?? this.storeId,
    );
  }
}
