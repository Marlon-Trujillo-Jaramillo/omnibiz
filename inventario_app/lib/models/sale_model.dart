import 'package:isar/isar.dart';

part 'sale_model.g.dart';

@collection
class Sale {
  Id id = Isar.autoIncrement;

  late List<SaleItem> items;
  late double totalAmount;
  late double taxAmount;
  late double discountAmount;
  late DateTime createdAt;

  // Payment: 'Cash', 'Card', 'Credit', 'Fiado'
  late String paymentMethod;

  int? customerId;

  // Business ID or context (Restaurant/Retail)
  late String businessContext;
}

@embedded
class SaleItem {
  late int productId;
  late String productName;
  late int quantity;
  late double unitPrice;
  late double totalPrice;
  late List<String> selectedVariants;
}
