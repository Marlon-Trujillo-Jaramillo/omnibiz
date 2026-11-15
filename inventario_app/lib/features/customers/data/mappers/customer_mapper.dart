import 'package:inventario_app/features/customers/data/models/customer_model.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';

extension CustomerModelMapper on Customer {
  CustomerEntity toEntity() => CustomerEntity(
    id: id,
    name: name,
    totalDebt: totalDebt,
    createdAt: createdAt,
    storeId: storeId,
    phone: phone,
    email: email,
    lastTransaction: lastTransaction,
  );
}

extension CustomerEntityMapper on CustomerEntity {
  Customer toModel() => Customer(
    id: id,
    name: name,
    totalDebt: totalDebt,
    createdAt: createdAt,
    storeId: storeId,
    phone: phone,
    email: email,
    lastTransaction: lastTransaction,
  );
}
