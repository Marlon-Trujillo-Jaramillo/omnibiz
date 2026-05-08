import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/core/isar_provider.dart';
import 'package:inventario_app/features/sales/cart_provider.dart';
import 'package:inventario_app/features/sales/sales_provider.dart';
import 'package:inventario_app/features/customers/customers_provider.dart';
import 'package:inventario_app/models/product_model.dart';
import 'package:inventario_app/models/sale_model.dart';
import 'package:inventario_app/models/customer_model.dart';
import 'package:inventario_app/core/receipt_service.dart';
import 'package:inventario_app/widgets/barcode_scanner_button.dart';

final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);
final _posSearchProvider = StateProvider<String>((ref) => '');

class POSScreen extends ConsumerWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProducts = ref.watch(productsProvider);
    final searchQuery = ref.watch(_posSearchProvider);
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).totalAmount;
    final selectedCustomer = ref.watch(selectedCustomerProvider);

    final filteredProducts = searchQuery.isEmpty
        ? allProducts
        : allProducts
            .where(
              (p) =>
                  p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  (p.barcode?.contains(searchQuery) ?? false) ||
                  p.sku.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Terminal de Venta'),
        actions: [
          if (cartItems.isNotEmpty)
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.shoppingCart),
                  onPressed: () => _showCartSheet(context, ref),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.indigoAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartItems.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            tooltip: 'Vaciar carrito',
            onPressed: cartItems.isEmpty
                ? null
                : () {
                    ref.read(cartProvider.notifier).clearCart();
                    ref.read(selectedCustomerProvider.notifier).state = null;
                  },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 700) {
            return _buildWideLayout(
              context, ref, filteredProducts, cartItems, total, selectedCustomer,
            );
          }
          return _buildNarrowLayout(
            context, ref, filteredProducts, allProducts, cartItems, total, selectedCustomer,
          );
        },
      ),
    );
  }

  // ── Wide (tablet) layout ────────────────────────────────────────────────────

  Widget _buildWideLayout(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
    List<SaleItem> cartItems,
    double total,
    Customer? selectedCustomer,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchBar(allProducts: ref.read(productsProvider)),
                const SizedBox(height: 24),
                Expanded(child: _ProductGrid(products: products, columns: 3)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _CartPanel(
            cartItems: cartItems,
            total: total,
            selectedCustomer: selectedCustomer,
            onCheckout: () => _showCheckout(context, total, ref),
          ),
        ),
      ],
    );
  }

  // ── Narrow (phone) layout ───────────────────────────────────────────────────

  Widget _buildNarrowLayout(
    BuildContext context,
    WidgetRef ref,
    List<Product> filteredProducts,
    List<Product> allProducts,
    List<SaleItem> cartItems,
    double total,
    Customer? selectedCustomer,
  ) {
    final itemCount = cartItems.fold(0, (s, i) => s + i.quantity);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _SearchBar(allProducts: allProducts),
        ),
        const SizedBox(height: 12),
        Expanded(child: _ProductGrid(products: filteredProducts, columns: 2)),
        if (cartItems.isNotEmpty)
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$itemCount ítem${itemCount != 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _showCartSheet(context, ref),
                      child: const Text('Carrito'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                      ),
                      onPressed: () => _showCheckout(context, total, ref),
                      child: const Text('Cobrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Cart bottom sheet (phone) ───────────────────────────────────────────────

  void _showCartSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final items = ref.watch(cartProvider);
          final total = ref.watch(cartProvider.notifier).totalAmount;
          final customer = ref.watch(selectedCustomerProvider);
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scroll) => Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Carrito',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(LucideIcons.trash2, size: 14),
                        label: const Text('Vaciar'),
                        onPressed: () {
                          ref.read(cartProvider.notifier).clearCart();
                          ref.read(selectedCustomerProvider.notifier).state = null;
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CustomerSelector(customer: customer),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _CartItemTile(item: items[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.indigoAccent,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: items.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _showCheckout(context, total, ref);
                                },
                          child: const Text(
                            'Cobrar Ahora',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCheckout(BuildContext context, double total, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => _CheckoutSheet(total: total),
    );
  }
}

// ── Search bar ──────────────────────────────────────────────────────────────

class _SearchBar extends ConsumerWidget {
  final List<Product> allProducts;
  const _SearchBar({required this.allProducts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => ref.read(_posSearchProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(LucideIcons.search),
              filled: true,
              fillColor: Colors.white.withAlpha(5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        BarcodeScannerButton(
          onResult: (code) {
            final product = allProducts.firstWhere(
              (p) => p.barcode == code || p.sku == code,
              orElse: () => Product()..name = 'Not Found',
            );
            if (product.name != 'Not Found') {
              ref.read(cartProvider.notifier).addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Añadido: ${product.name}')),
              );
            }
          },
        ),
      ],
    );
  }
}

// ── Product grid ────────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final int columns;
  const _ProductGrid({required this.products, required this.columns});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Sin productos que coincidan',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductGridTile(product: products[i]),
    );
  }
}

// ── Product tile ────────────────────────────────────────────────────────────

class _ProductGridTile extends ConsumerWidget {
  final Product product;
  const _ProductGridTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: product.stock > 0
          ? () => ref.read(cartProvider.notifier).addToCart(product)
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: product.stock > 0 ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(5)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withAlpha(20),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.package,
                    color: product.stock > 0
                        ? Colors.indigoAccent
                        : Colors.redAccent,
                    size: 36,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          product.stock > 0
                              ? '${product.stock} u.'
                              : 'Agotado',
                          style: TextStyle(
                            color: product.stock > 0
                                ? Colors.white38
                                : Colors.redAccent,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cart panel (wide layout) ────────────────────────────────────────────────

class _CartPanel extends ConsumerWidget {
  final List<SaleItem> cartItems;
  final double total;
  final Customer? selectedCustomer;
  final VoidCallback onCheckout;

  const _CartPanel({
    required this.cartItems,
    required this.total,
    required this.selectedCustomer,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Column(
        children: [
          const Text(
            'Resumen de Orden',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _CustomerSelector(customer: selectedCustomer),
          const SizedBox(height: 12),
          Expanded(
            child: cartItems.isEmpty
                ? const Center(
                    child: Text(
                      'El carrito está vacío',
                      style: TextStyle(color: Colors.white24),
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (_, i) => _CartItemTile(item: cartItems[i]),
                  ),
          ),
          const Divider(color: Colors.white10, height: 32),
          _SummaryRow('Subtotal', '\$${total.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _SummaryRow('Impuestos (0%)', '\$0.00'),
          const SizedBox(height: 10),
          _SummaryRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: cartItems.isEmpty ? null : onCheckout,
              child: const Text(
                'Cobrar Ahora',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customer selector ───────────────────────────────────────────────────────

class _CustomerSelector extends ConsumerWidget {
  final Customer? customer;
  const _CustomerSelector({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A1A1A),
          builder: (_) => ListView.builder(
            itemCount: customers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(LucideIcons.userX),
                  title: const Text('Sin cliente'),
                  onTap: () {
                    ref.read(selectedCustomerProvider.notifier).state = null;
                    Navigator.pop(context);
                  },
                );
              }
              final c = customers[index - 1];
              return ListTile(
                leading: const Icon(LucideIcons.user),
                title: Text(c.name),
                subtitle: Text('Deuda: \$${c.totalDebt.toStringAsFixed(2)}'),
                onTap: () {
                  ref.read(selectedCustomerProvider.notifier).state = c;
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(8)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.user, color: Colors.indigoAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                customer?.name ?? 'Seleccionar cliente',
                style: TextStyle(
                  color: customer != null ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (customer != null)
              GestureDetector(
                onTap: () =>
                    ref.read(selectedCustomerProvider.notifier).state = null,
                child: const Icon(LucideIcons.x, size: 14, color: Colors.white38),
              ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronRight, size: 14, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

// ── Cart item tile ──────────────────────────────────────────────────────────

class _CartItemTile extends ConsumerWidget {
  final SaleItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '\$${item.unitPrice.toStringAsFixed(2)} c/u',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QuantityControl(
            quantity: item.quantity,
            onDecrease: () =>
                ref.read(cartProvider.notifier).decreaseQuantity(item.productId),
            onIncrease: () =>
                ref.read(cartProvider.notifier).increaseQuantity(item.productId),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              '\$${item.totalPrice.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(cartProvider.notifier).removeFromCart(item.productId),
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(LucideIcons.x, size: 14, color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyBtn(icon: LucideIcons.minus, onTap: onDecrease),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        _QtyBtn(icon: LucideIcons.plus, onTap: onIncrease),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 11, color: Colors.white54),
      ),
    );
  }
}

// ── Summary row ─────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow(this.label, this.value, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.white38,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? Colors.indigoAccent : Colors.white,
            fontSize: isTotal ? 22 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ── Checkout sheet ──────────────────────────────────────────────────────────

class _CheckoutSheet extends ConsumerStatefulWidget {
  final double total;
  const _CheckoutSheet({required this.total});

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  String selectedMethod = 'Efectivo';
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final selectedCustomer = ref.watch(selectedCustomerProvider);

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Finalizar Venta',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            '\$${widget.total.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Método de pago:',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MethodCard(
                  icon: LucideIcons.banknote,
                  label: 'Efectivo',
                  isSelected: selectedMethod == 'Efectivo',
                  onTap: () => setState(() => selectedMethod = 'Efectivo'),
                ),
                const SizedBox(width: 12),
                _MethodCard(
                  icon: LucideIcons.creditCard,
                  label: 'Tarjeta',
                  isSelected: selectedMethod == 'Tarjeta',
                  onTap: () => setState(() => selectedMethod = 'Tarjeta'),
                ),
                const SizedBox(width: 12),
                if (selectedCustomer != null)
                  _MethodCard(
                    icon: LucideIcons.userMinus,
                    label: 'Fiado',
                    isSelected: selectedMethod == 'Fiado',
                    onTap: () => setState(() => selectedMethod = 'Fiado'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isProcessing ? null : _confirmSale,
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Confirmar y Generar Recibo',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSale() async {
    setState(() => isProcessing = true);

    final cartItems = ref.read(cartProvider);
    final isar = ref.read(isarProvider);
    final selectedCustomer = ref.read(selectedCustomerProvider);

    final sale = Sale()
      ..items = cartItems
      ..totalAmount = widget.total
      ..taxAmount = 0
      ..discountAmount = 0
      ..paymentMethod = selectedMethod
      ..customerId = selectedCustomer?.id
      ..businessContext = 'generic'
      ..createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.sales.put(sale);

      for (var item in cartItems) {
        final product = await isar.products.get(item.productId);
        if (product != null) {
          product.stock -= item.quantity;
          await isar.products.put(product);
        }
      }

      if (selectedMethod == 'Fiado' && selectedCustomer != null) {
        final customer = await isar.customers.get(selectedCustomer.id);
        if (customer != null) {
          customer.totalDebt += widget.total;
          customer.lastTransaction = DateTime.now();
          await isar.customers.put(customer);
        }
      }
    });

    ref.read(productsProvider.notifier).loadProducts();
    ref.read(salesProvider.notifier).refresh();
    ref.read(customersProvider.notifier).loadCustomers();
    ref.read(cartProvider.notifier).clearCart();
    ref.read(selectedCustomerProvider.notifier).state = null;

    await ReceiptService.generateAndPrintReceipt(sale);

    if (mounted) {
      Navigator.pop(context);
      _showSuccessDialog(context);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Venta Completada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'El inventario ha sido actualizado y el recibo generado.',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment method card ──────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.indigoAccent.withAlpha(20)
              : Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.indigoAccent : Colors.white.withAlpha(5),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.indigoAccent : Colors.white38,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.white38,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
