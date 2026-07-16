import 'package:inventario_app/features/sales/data/models/sale_model.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';

extension SaleModelMapper on Sale {
  SaleEntity toEntity() => SaleEntity(
        id:              id,
        items:           items.map((i) => i.toEntity()).toList(),
        totalAmount:     totalAmount,
        taxAmount:       taxAmount,
        discountAmount:  discountAmount,
        paymentMethod:   paymentMethod,
        businessContext: businessContext,
        createdAt:       createdAt,
        storeId:         storeId,
        customerId:      customerId,
      );
}

extension SaleItemModelMapper on SaleItem {
  SaleItemEntity toEntity() => SaleItemEntity(
        productId:        productId,
        productName:      productName,
        quantity:         quantity,
        unitPrice:        unitPrice,
        totalPrice:       totalPrice,
        selectedVariants: selectedVariants,
      );
}

extension SaleEntityMapper on SaleEntity {
  Sale toModel() => Sale(
        id:              id,
        items:           items.map((i) => i.toModel()).toList(),
        totalAmount:     totalAmount,
        taxAmount:       taxAmount,
        discountAmount:  discountAmount,
        paymentMethod:   paymentMethod,
        businessContext: businessContext,
        createdAt:       createdAt,
        storeId:         storeId,
        customerId:      customerId,
      );
}

extension SaleItemEntityMapper on SaleItemEntity {
  SaleItem toModel() => SaleItem(
        productId:        productId,
        productName:      productName,
        quantity:         quantity,
        unitPrice:        unitPrice,
        totalPrice:       totalPrice,
        selectedVariants: selectedVariants,
      );
}

extension CartItemToSaleItem on CartItemEntity {
  SaleItemEntity toSaleItemEntity() => SaleItemEntity(
        productId:        productId,
        productName:      productName,
        quantity:         quantity,
        unitPrice:        unitPrice,
        totalPrice:       totalPrice,
        selectedVariants: selectedVariants,
      );
}
