import 'package:isar/isar.dart';

part 'product_model.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  late String name;
  late String category;
  late double price;
  late double costPrice;
  late int stock;
  late String sku;
  String? barcode;

  // Custom metadata for different business types
  // e.g., 'size:M,color:red' for clothing
  // e.g., 'ingredients:tomato,cheese' for food
  late List<String> variants;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool get isLowStock => stock < 5;
  double get margin => (price - costPrice) / price;
}

@collection
class Category {
  Id id = Isar.autoIncrement;
  late String name;
  late String icon; // Icon name as string
}
