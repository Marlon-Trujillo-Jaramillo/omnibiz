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

class POSScreen extends ConsumerWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).totalAmount;
    final selectedCustomer = ref.watch(selectedCustomerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Terminal de Punto de Venta'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              ref.read(selectedCustomerProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: Product Selection
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSearchBar(ref, products)),
                      const SizedBox(width: 12),
                      BarcodeScannerButton(
                        onResult: (code) {
                          final product = products.firstWhere(
                            (p) => p.barcode == code || p.sku == code,
                            orElse: () => Product()..name = 'Not Found',
                          );
                          if (product.name != 'Not Found') {
                            ref.read(cartProvider.notifier).addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Añadido: ${product.name}'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: products.isEmpty
                        ? const Center(
                            child: Text(
                              'Crea productos en el inventario primero',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return _ProductGridTile(product: product);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Cart & Checkout
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(5)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Resumen de Orden',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Customer Selection
                  _buildCustomerSelector(context, ref, selectedCustomer),
                  const SizedBox(height: 16),

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
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              return _CartItemTile(item: item);
                            },
                          ),
                  ),
                  const Divider(color: Colors.white10, height: 48),
                  _buildTotalSection(total),
                  const SizedBox(height: 24),
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
                      onPressed: cartItems.isEmpty
                          ? null
                          : () => _showCheckout(context, total, ref),
                      child: const Text(
                        'Cobrar Ahora',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref, List<Product> products) {
    return TextField(
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
    );
  }

  Widget _buildCustomerSelector(
    BuildContext context,
    WidgetRef ref,
    Customer? customer,
  ) {
    final customers = ref.watch(customersProvider);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A1A1A),
          builder: (context) => ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final c = customers[index];
              return ListTile(
                leading: const Icon(LucideIcons.user),
                title: Text(c.name),
                subtitle: Text('Deuda: \$${c.totalDebt}'),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(5)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.user, color: Colors.indigoAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                customer?.name ?? 'Seleccionar Cliente',
                style: TextStyle(
                  color: customer != null ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (customer != null)
              IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
                onPressed: () =>
                    ref.read(selectedCustomerProvider.notifier).state = null,
              ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(double total) {
    return Column(
      children: [
        _buildSummaryRow('Subtotal', '\$${total.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _buildSummaryRow('Impuestos (0%)', '\$0.00'),
        const SizedBox(height: 12),
        _buildSummaryRow(
          'Total',
          '\$${total.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.white38,
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? Colors.indigoAccent : Colors.white,
            fontSize: isTotal ? 24 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
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

class _ProductGridTile extends ConsumerWidget {
  final Product product;
  const _ProductGridTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: product.stock > 0
          ? () => ref.read(cartProvider.notifier).addToCart(product)
          : null,
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
                    size: 40,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          product.stock > 0
                              ? '${product.stock} un.'
                              : 'Agotado',
                          style: TextStyle(
                            color: product.stock > 0
                                ? Colors.white38
                                : Colors.redAccent,
                            fontSize: 11,
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

class _CartItemTile extends ConsumerWidget {
  final SaleItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigoAccent.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '${item.quantity}x',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigoAccent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '\$${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 16, color: Colors.white24),
            onPressed: () =>
                ref.read(cartProvider.notifier).removeFromCart(item.productId),
          ),
        ],
      ),
    );
  }
}

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
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '\$${widget.total.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'Seleccione método de pago:',
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
                const SizedBox(width: 16),
                _MethodCard(
                  icon: LucideIcons.creditCard,
                  label: 'Tarjeta',
                  isSelected: selectedMethod == 'Tarjeta',
                  onTap: () => setState(() => selectedMethod = 'Tarjeta'),
                ),
                const SizedBox(width: 16),
                if (selectedCustomer != null)
                  _MethodCard(
                    icon: LucideIcons.userMinus,
                    label: 'Fiado/Crédito',
                    isSelected: selectedMethod == 'Fiado',
                    onTap: () => setState(() => selectedMethod = 'Fiado'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isProcessing ? null : _confirmSale,
              child: isProcessing
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Confirmar y Generar Recibo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSale() async {
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

      // Update inventory stock
      for (var item in cartItems) {
        final product = await isar.products.get(item.productId);
        if (product != null) {
          product.stock -= item.quantity;
          await isar.products.put(product);
        }
      }

      // Update customer debt if payment is "Fiado"
      if (selectedMethod == 'Fiado' && selectedCustomer != null) {
        final customer = await isar.customers.get(selectedCustomer.id);
        if (customer != null) {
          customer.totalDebt += widget.total;
          customer.lastTransaction = DateTime.now();
          await isar.customers.put(customer);
        }
      }
    });

    // Refresh data
    ref.read(productsProvider.notifier).loadProducts();
    ref.read(salesProvider.notifier).refresh();
    ref.read(customersProvider.notifier).loadCustomers();
    ref.read(cartProvider.notifier).clearCart();
    ref.read(selectedCustomerProvider.notifier).state = null;

    // Auto-print receipt
    await ReceiptService.generateAndPrintReceipt(sale);

    if (mounted) {
      Navigator.pop(context); // Close sheet
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
            const Icon(
              LucideIcons.checkCircle2,
              color: Colors.greenAccent,
              size: 64,
            ),
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
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
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
              size: 32,
              color: isSelected ? Colors.indigoAccent : Colors.white38,
            ),
            const SizedBox(height: 12),
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
