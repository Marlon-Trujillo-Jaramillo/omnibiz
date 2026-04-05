import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/models/product_model.dart';
import 'package:inventario_app/models/sale_model.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<SaleItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<SaleItem>> {
  CartNotifier() : super([]);

  void addToCart(Product product, {List<String>? selectedVariants}) {
    final existingIndex = state.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            SaleItem()
              ..productId = state[i].productId
              ..productName = state[i].productName
              ..quantity = state[i].quantity + 1
              ..unitPrice = state[i].unitPrice
              ..totalPrice = (state[i].quantity + 1) * state[i].unitPrice
              ..selectedVariants = selectedVariants ?? []
          else
            state[i],
      ];
    } else {
      state = [
        ...state,
        SaleItem()
          ..productId = product.id
          ..productName = product.name
          ..quantity = 1
          ..unitPrice = product.price
          ..totalPrice = product.price
          ..selectedVariants = selectedVariants ?? [],
      ];
    }
  }

  void removeFromCart(int productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount => state.fold(0, (sum, item) => sum + item.totalPrice);
}
