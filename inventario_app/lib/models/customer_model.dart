import 'package:isar/isar.dart';

part 'customer_model.g.dart';

@collection
class Customer {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String name;

  String? phone;
  String? email;

  double totalDebt = 0.0; // Current balance (debt if positive)

  DateTime createdAt = DateTime.now();

  @Index()
  DateTime? lastTransaction;
}
