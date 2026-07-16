import 'package:inventario_app/features/inventory/data/models/product_model.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';

extension ProductModelMapper on Product {
  ProductEntity toEntity() => ProductEntity(
        id:        id,
        name:      name,
        category:  category,
        price:     price,
        costPrice: costPrice,
        stock:     stock,
        sku:       sku,
        variants:  variants,
        createdAt: createdAt,
        updatedAt: updatedAt,
        storeId:   storeId,
        barcode:   barcode,
      );
}

extension ProductEntityMapper on ProductEntity {
  Product toModel() => Product(
        id:        id,
        name:      name,
        category:  category,
        price:     price,
        costPrice: costPrice,
        stock:     stock,
        sku:       sku,
        variants:  variants,
        createdAt: createdAt,
        updatedAt: updatedAt,
        storeId:   storeId,
        barcode:   barcode,
      );
}

extension CategoryModelMapper on Category {
  CategoryEntity toEntity() =>
      CategoryEntity(id: id, name: name, icon: icon, storeId: storeId);
}

extension CategoryEntityMapper on CategoryEntity {
  Category toModel() =>
      Category(id: id, name: name, icon: icon, storeId: storeId);
}
