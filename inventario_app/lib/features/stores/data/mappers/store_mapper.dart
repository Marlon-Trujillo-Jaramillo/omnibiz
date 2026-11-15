import 'package:inventario_app/features/stores/data/models/store_model.dart';
import 'package:inventario_app/features/stores/domain/entities/store_entity.dart';

extension StoreModelMapper on Store {
  StoreEntity toEntity() => StoreEntity(
    id: id,
    name: name,
    icon: icon,
    createdAt: createdAt,
    address: address,
  );
}

extension StoreEntityMapper on StoreEntity {
  Store toModel() => Store(
    id: id,
    name: name,
    icon: icon,
    createdAt: createdAt,
    address: address,
  );
}
