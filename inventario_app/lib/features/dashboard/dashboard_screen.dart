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

class DashboardScreen extends ConsumerWidget {
  final String businessType;

  const DashboardScreen({super.key, required this.businessType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final sales = ref.watch(salesProvider);
    final theme = Theme.of(context);

    final dailyTotal = sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatusOverview(context, products.length, dailyTotal),
                  const SizedBox(height: 32),
                  const SalesChart(),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Acciones Rápidas'),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Stock Reciente'),
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
            MaterialPageRoute(builder: (c) => const POSScreen()),
          );
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('Nueva Venta'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
                'Hola, Admin • ${businessType == 'retail' ? 'Comercio' : 'Restaurante'}',
                style: const TextStyle(
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverview(
    BuildContext context,
    int productCount,
    double totalSales,
  ) {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            title: 'Ventas Semanales',
            value: '\$${totalSales.toStringAsFixed(2)}',
            icon: LucideIcons.trendingUp,
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _OverviewCard(
            title: 'Stock Total',
            value: '$productCount',
            icon: LucideIcons.box,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
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
                  builder: (c) => AddProductScreen(businessType: businessType),
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
                MaterialPageRoute(builder: (c) => const POSScreen()),
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
                MaterialPageRoute(builder: (c) => const CustomersScreen()),
              );
            },
          ),
          _QuickActionItem(
            label: 'Ver Reportes',
            icon: LucideIcons.barChart,
            color: Colors.cyanAccent,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
          _buildDrawerItem(
            LucideIcons.home,
            'Inicio',
            () => Navigator.pop(context),
          ),
          _buildDrawerItem(LucideIcons.package, 'Inventario', () {}),
          _buildDrawerItem(LucideIcons.shoppingBag, 'Ventas', () {}),
          _buildDrawerItem(LucideIcons.users, 'Clientes', () {}),
          const Spacer(),
          _buildDrawerItem(LucideIcons.settings, 'Configuración', () {}),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

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
        width: 140,
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
            Icon(icon, color: color, size: 28),
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

class _ProductListItem extends StatelessWidget {
  final dynamic product;
  const _ProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.indigoAccent.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.package,
              color: Colors.indigoAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${product.stock} unidades en stock',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${product.price}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
