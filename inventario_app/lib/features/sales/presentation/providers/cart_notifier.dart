import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';

// ── Session state ──────────────────────────────────────────────────────────────

class PosSessionState {
  const PosSessionState({this.items = const [], this.selectedCustomerId});

  final List<CartItemEntity> items;
  final int? selectedCustomerId;

  PosSessionState copyWith({
    List<CartItemEntity>? items,
    int? selectedCustomerId,
    bool clearCustomer = false,
  }) {
    return PosSessionState(
      items: items ?? this.items,
      selectedCustomerId: clearCustomer
          ? null
          : (selectedCustomerId ?? this.selectedCustomerId),
    );
  }

  /// Centavos.
  int get total => items.fold(0, (sum, i) => sum + i.totalPrice);
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
}

// ── Provider ───────────────────────────────────────────────────────────────────

final cartProvider = NotifierProvider<CartNotifier, PosSessionState>(
  CartNotifier.new,
);

// ── Notifier ───────────────────────────────────────────────────────────────────

class CartNotifier extends Notifier<PosSessionState> {
  /// El carrito pertenece a una sucursal: al cambiar de sucursal se vacía
  /// (sus productos/cliente no existen en la otra).
  @override
  PosSessionState build() {
    ref.watch(currentStoreProvider);
    return const PosSessionState();
  }

  void addProduct(ProductEntity product, {List<String> variants = const []}) {
    final idx = state.items.indexWhere((i) => i.productId == product.id);
    if (idx >= 0) {
      state = state.copyWith(
        items: [
          for (int i = 0; i < state.items.length; i++)
            if (i == idx)
              state.items[i].copyWith(quantity: state.items[i].quantity + 1)
            else
              state.items[i],
        ],
      );
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItemEntity(
            productId: product.id,
            productName: product.name,
            quantity: 1,
            unitPrice: product.price,
            selectedVariants: variants,
          ),
        ],
      );
    }
  }

  void increase(int productId) {
    final idx = state.items.indexWhere((i) => i.productId == productId);
    if (idx < 0) return;
    state = state.copyWith(
      items: [
        for (int i = 0; i < state.items.length; i++)
          if (i == idx)
            state.items[i].copyWith(quantity: state.items[i].quantity + 1)
          else
            state.items[i],
      ],
    );
  }

  void decrease(int productId) {
    final idx = state.items.indexWhere((i) => i.productId == productId);
    if (idx < 0) return;
    if (state.items[idx].quantity <= 1) {
      remove(productId);
      return;
    }
    state = state.copyWith(
      items: [
        for (int i = 0; i < state.items.length; i++)
          if (i == idx)
            state.items[i].copyWith(quantity: state.items[i].quantity - 1)
          else
            state.items[i],
      ],
    );
  }

  void remove(int productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
  }

  /// Sets the exact quantity for an item already in the cart.
  /// A quantity of 0 or less removes the item.
  void setQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final idx = state.items.indexWhere((i) => i.productId == productId);
    if (idx < 0) return;
    state = state.copyWith(
      items: [
        for (int i = 0; i < state.items.length; i++)
          if (i == idx)
            state.items[i].copyWith(quantity: quantity)
          else
            state.items[i],
      ],
    );
  }

  /// Adds [quantity] units of [product] in one shot instead of tapping
  /// the product tile repeatedly.
  void addProductQuantity(
    ProductEntity product,
    int quantity, {
    List<String> variants = const [],
  }) {
    if (quantity <= 0) return;
    final idx = state.items.indexWhere((i) => i.productId == product.id);
    if (idx >= 0) {
      state = state.copyWith(
        items: [
          for (int i = 0; i < state.items.length; i++)
            if (i == idx)
              state.items[i].copyWith(
                quantity: state.items[i].quantity + quantity,
              )
            else
              state.items[i],
        ],
      );
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItemEntity(
            productId: product.id,
            productName: product.name,
            quantity: quantity,
            unitPrice: product.price,
            selectedVariants: variants,
          ),
        ],
      );
    }
  }

  void selectCustomer(int? id) {
    state = id == null
        ? state.copyWith(clearCustomer: true)
        : state.copyWith(selectedCustomerId: id);
  }

  void clear() => state = const PosSessionState();
}
