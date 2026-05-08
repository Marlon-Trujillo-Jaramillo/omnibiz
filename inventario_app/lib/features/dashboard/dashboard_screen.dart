import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/core/isar_provider.dart';
import 'package:inventario_app/features/inventory/add_product_screen.dart';
import 'package:inventario_app/features/sales/pos_screen.dart';
import 'package:inventario_app/widgets/sales_chart.dart';
import 'package:inventario_app/features/sales/sales_provider.dart';
import 'package:inventario_app/features/customers/customers_screen.dart';
import 'package:inventario_app/models/product_model.dart';

class DashboardScreen extends ConsumerWidget {
  final String businessType;

  const DashboardScreen({super.key, required this.businessType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final sales = ref.watch(salesProvider);
    final theme = Theme.of(context);

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weeklyTotal = sales
        .where((s) => s.createdAt.isAfter(weekAgo))
        .fold(0.0, (sum, s) => sum + s.totalAmount);

    final lowStock = products.where((p) => p.isLowStock && p.stock > 0).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(context, ref),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatusOverview(context, products, weeklyTotal),
                  const SizedBox(height: 32),
                  const SalesChart(),
                  const SizedBox(height: 32),
                  _sectionTitle('Acciones Rápidas'),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  if (lowStock.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _LowStockSection(products: lowStock),
                  ],
                  const SizedBox(height: 32),
                  _sectionTitle('Inventario Reciente'),
                  const SizedBox(height: 16),
                  if (products.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No hay productos aún',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                  else
                    ...products.reversed
                        .take(5)
                        .map((p) => _ProductListItem(product: p)),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const POSScreen()),
          );
        },
        icon: const Icon(LucideIcons.shoppingCart),
        label: const Text('Nueva Venta'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final typeLabel = businessType == 'retail'
        ? 'Comercio / Retail'
        : businessType == 'fnb'
            ? 'Restaurante / Bar'
            : 'Local Comercial';

    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel Principal',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Hola, Admin · $typeLabel',
                style: const TextStyle(color: Colors.white54, letterSpacing: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverview(
    BuildContext context,
    List<Product> products,
    double weeklyTotal,
  ) {
    final totalStock = products.fold(0, (s, p) => s + p.stock);

    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            title: 'Ventas 7 días',
            value: '\$${weeklyTotal.toStringAsFixed(2)}',
            icon: LucideIcons.trendingUp,
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _OverviewCard(
            title: 'Unidades en Stock',
            value: '$totalStock',
            icon: LucideIcons.box,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _QuickActionItem(
            label: 'Añadir Producto',
            icon: LucideIcons.plusCircle,
            color: Colors.purpleAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddProductScreen(businessType: businessType),
                ),
              );
            },
          ),
          _QuickActionItem(
            label: 'Terminal POS',
            icon: LucideIcons.calculator,
            color: Colors.amberAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const POSScreen()),
              );
            },
          ),
          _QuickActionItem(
            label: 'Clientes',
            icon: LucideIcons.users,
            color: Colors.greenAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomersScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFF141414),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.bottomLeft,
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
            ),
            child: Text(
              'OmniBiz',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _drawerItem(LucideIcons.home, 'Inicio', () => Navigator.pop(context)),
          _drawerItem(LucideIcons.plusCircle, 'Añadir Producto', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddProductScreen(businessType: businessType),
              ),
            );
          }),
          _drawerItem(LucideIcons.shoppingCart, 'Terminal POS', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const POSScreen()),
            );
          }),
          _drawerItem(LucideIcons.users, 'Clientes', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomersScreen()),
            );
          }),
          const Spacer(),
          const Divider(color: Colors.white12),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'OmniBiz Automation v1.0',
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 20),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

// ── Low stock section ────────────────────────────────────────────────────────

class _LowStockSection extends StatelessWidget {
  final List<Product> products;
  const _LowStockSection({required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.amberAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              'Stock Bajo (${products.length})',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.amberAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...products.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withAlpha(8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amberAccent.withAlpha(30)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.package, color: Colors.amberAccent, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${p.stock} restantes',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Overview card ────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick action ─────────────────────────────────────────────────────────────

class _QuickActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product list item ────────────────────────────────────────────────────────

class _ProductListItem extends ConsumerWidget {
  final Product product;
  const _ProductListItem({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.indigoAccent.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.package,
              color: Colors.indigoAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '${product.stock} en stock',
                      style: TextStyle(
                        color: product.isLowStock
                            ? Colors.amberAccent
                            : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    if (product.isLowStock) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.alertTriangle,
                        size: 11,
                        color: Colors.amberAccent,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 16, color: Colors.white38),
            color: const Color(0xFF2A2A2A),
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddProductScreen(
                      businessType: 'generic',
                      product: product,
                    ),
                  ),
                );
              } else if (v == 'delete') {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text('Eliminar producto'),
                    content: Text('¿Eliminar "${product.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        onPressed: () {
                          ref
                              .read(productsProvider.notifier)
                              .deleteProduct(product.id);
                          Navigator.pop(context);
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(LucideIcons.pencil, size: 15),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 15, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
