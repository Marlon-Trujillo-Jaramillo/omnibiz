import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/features/inventory/presentation/providers/products_notifier.dart';
import 'package:inventario_app/features/sales/presentation/providers/sales_notifier.dart';
import 'package:inventario_app/shared/widgets/sales_chart.dart';

// ── Derived provider — computed once, shared across the subtree ────────────────
final _dashboardStatsProvider = Provider.autoDispose<
    ({double weekTotal, int totalStock, List<ProductEntity> lowStock})>((ref) {
  final products = ref.watch(productsProvider).valueOrNull ?? [];
  final sales    = ref.watch(salesProvider).valueOrNull   ?? [];
  final weekAgo  = DateTime.now().subtract(const Duration(days: 7));

  return (
    weekTotal:  sales
        .where((s) => s.createdAt.isAfter(weekAgo))
        .fold(0.0, (sum, s) => sum + s.totalAmount),
    totalStock: products.fold(0, (s, p) => s + p.stock),
    lowStock:   products.where((p) => p.isLowStock && !p.isOutOfStock).toList(),
  );
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.businessType});
  final String businessType;

  String get _typeLabel => switch (businessType) {
        'retail' => 'Comercio / Retail',
        'fnb'    => 'Restaurante / Bar',
        _        => 'Local Comercial',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider).valueOrNull ?? [];
    final stats    = ref.watch(_dashboardStatsProvider);

    return Scaffold(
      backgroundColor: OmniColors.bg,
      drawer: _DashboardDrawer(businessType: businessType),
      floatingActionButton: _NewSaleFab(businessType: businessType),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _DashboardAppBar(typeLabel: _typeLabel),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _KpiRow(weekTotal: stats.weekTotal, totalStock: stats.totalStock),
                  const SizedBox(height: OmniSpacing.xxl),
                  const SalesChart(),
                  const SizedBox(height: OmniSpacing.xxl),
                  Text('Acciones Rápidas', style: OmniTypography.headingMd),
                  const SizedBox(height: OmniSpacing.base),
                  _QuickActionsGrid(businessType: businessType),
                  if (stats.lowStock.isNotEmpty) ...[
                    const SizedBox(height: OmniSpacing.xxl),
                    _LowStockSection(products: stats.lowStock),
                  ],
                  const SizedBox(height: OmniSpacing.xxl),
                  _InventoryHeader(products: products),
                  const SizedBox(height: OmniSpacing.base),
                  _InventoryList(products: products, businessType: businessType),
                  const SizedBox(height: OmniSpacing.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AppBar ─────────────────────────────────────────────────────────────────────
class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar({required this.typeLabel});
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: context.isTablet ? 140 : 110,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(LucideIcons.menu, color: OmniColors.textSecondary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.bell, color: OmniColors.textSecondary),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(
            OmniSpacing.xl, 0, OmniSpacing.xl, OmniSpacing.base),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Panel Principal', style: OmniTypography.displayMd),
              const SizedBox(height: OmniSpacing.xs),
              Text('Admin · $typeLabel', style: OmniTypography.bodySm),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KPI Row ────────────────────────────────────────────────────────────────────
class _KpiRow extends ConsumerWidget {
  const _KpiRow({required this.weekTotal, required this.totalStock});

  final double weekTotal;
  final int totalStock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OmniStatCard(
            title: 'Ventas 7 días',
            value: ref.formatMoneyCompact(weekTotal),
            icon: LucideIcons.trendingUp,
            color: OmniColors.success,
          ),
        ),
        const SizedBox(width: OmniSpacing.base),
        Expanded(
          child: OmniStatCard(
            title: 'Unidades en stock',
            value: '$totalStock',
            icon: LucideIcons.box,
            color: OmniColors.primary,
          ),
        ),
      ],
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.businessType});
  final String businessType;

  static const _actions = [
    (label: 'Añadir Producto', icon: LucideIcons.plusCircle,
     color: OmniColors.purple,  path: '/dashboard/inventory/add'),
    (label: 'Terminal POS',    icon: LucideIcons.calculator,
     color: OmniColors.warning, path: '/dashboard/pos'),
    (label: 'Clientes',        icon: LucideIcons.users,
     color: OmniColors.success, path: '/dashboard/customers'),
    (label: 'Analytics',       icon: LucideIcons.barChart2,
     color: OmniColors.blue,    path: '/dashboard/analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final cols = constraints.maxWidth >= OmniBreakpoints.desktop
            ? _actions.length
            : constraints.maxWidth >= OmniBreakpoints.tablet
                ? 4
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: OmniSpacing.md,
            mainAxisSpacing: OmniSpacing.md,
            childAspectRatio: 1.1,
          ),
          itemCount: _actions.length,
          itemBuilder: (_, i) => _ActionCard(action: _actions[i]),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});
  final ({String label, IconData icon, Color color, String path}) action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(action.path),
      borderRadius: OmniRadius.xlAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.sm,
          vertical: OmniSpacing.md,
        ),
        decoration: BoxDecoration(
          color: action.color.withAlpha(12),
          borderRadius: OmniRadius.xlAll,
          border: Border.all(color: action.color.withAlpha(25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: OmniSpacing.xxl),
            const SizedBox(height: OmniSpacing.sm),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: OmniTypography.caption.copyWith(
                color: action.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Low Stock ──────────────────────────────────────────────────────────────────
class _LowStockSection extends StatelessWidget {
  const _LowStockSection({required this.products});
  final List<ProductEntity> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LowStockHeader(count: products.length),
        const SizedBox(height: OmniSpacing.md),
        ...products.map((p) => _LowStockTile(product: p)),
      ],
    );
  }
}

class _LowStockHeader extends StatelessWidget {
  const _LowStockHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.alertTriangle,
            color: OmniColors.warning, size: 18),
        const SizedBox(width: OmniSpacing.sm),
        Text(
          'Stock Bajo ($count)',
          style: OmniTypography.headingMd.copyWith(color: OmniColors.warning),
        ),
      ],
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.product});
  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: OmniSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.base,
        vertical: OmniSpacing.md,
      ),
      decoration: BoxDecoration(
        color: OmniColors.warningBg,
        borderRadius: OmniRadius.lgAll,
        border: Border.all(color: OmniColors.warning.withAlpha(40)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.package, color: OmniColors.warning, size: 16),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Text(product.name, style: OmniTypography.bodyMd,
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            '${product.stock} restantes',
            style: OmniTypography.label.copyWith(
              color: OmniColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inventory ──────────────────────────────────────────────────────────────────
class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({required this.products});
  final List<ProductEntity> products;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Inventario Reciente', style: OmniTypography.headingMd),
        if (products.isNotEmpty)
          TextButton(
            onPressed: () => context.go('/dashboard/inventory/add'),
            child: const Text('Ver todo'),
          ),
      ],
    );
  }
}

class _InventoryList extends StatelessWidget {
  const _InventoryList({required this.products, required this.businessType});
  final List<ProductEntity> products;
  final String businessType;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return OmniEmptyState(
        icon: LucideIcons.packageOpen,
        title: 'Sin productos',
        subtitle: 'Agrega tu primer producto para comenzar',
        actionLabel: 'Agregar producto',
        onAction: () => context.go('/dashboard/inventory/add'),
      );
    }
    return Column(
      children: products.reversed
          .take(5)
          .map((p) => _ProductTile(product: p, businessType: businessType))
          .toList(),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product, required this.businessType});
  final ProductEntity product;
  final String businessType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: OmniSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.base,
        vertical: OmniSpacing.md,
      ),
      decoration: BoxDecoration(
        color: OmniColors.bgSurface,
        borderRadius: OmniRadius.lgAll,
        border: Border.all(color: OmniColors.borderSubtle),
      ),
      child: Row(
        children: [
          OmniIconAvatar(icon: LucideIcons.package, color: OmniColors.primary),
          const SizedBox(width: OmniSpacing.md),
          Expanded(child: _ProductInfo(product: product)),
          Text(
            ref.formatMoney(product.price),
            style: OmniTypography.headingSm,
          ),
          const SizedBox(width: OmniSpacing.xs),
          _ProductMenu(product: product, ref: ref),
        ],
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});
  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.name, style: OmniTypography.headingSm,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              '${product.stock} en stock',
              style: OmniTypography.caption.copyWith(
                color: product.isLowStock
                    ? OmniColors.warning
                    : OmniColors.textMuted,
              ),
            ),
            if (product.isLowStock) ...[
              const SizedBox(width: OmniSpacing.xs),
              const Icon(LucideIcons.alertTriangle,
                  size: 11, color: OmniColors.warning),
            ],
          ],
        ),
      ],
    );
  }
}

class _ProductMenu extends StatelessWidget {
  const _ProductMenu({required this.product, required this.ref});
  final ProductEntity product;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical,
          size: 16, color: OmniColors.textMuted),
      color: OmniColors.bgPopup,
      onSelected: (v) => _onSelected(context, v),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: _MenuRow(icon: LucideIcons.pencil, label: 'Editar'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            icon: LucideIcons.trash2,
            label: 'Eliminar',
            color: OmniColors.danger,
          ),
        ),
      ],
    );
  }

  Future<void> _onSelected(BuildContext context, String value) async {
    if (value == 'edit') {
      context.go('/dashboard/inventory/${product.id}');
      return;
    }
    final ok = await OmniConfirmDialog.show(
      context,
      icon: LucideIcons.trash2,
      title: 'Eliminar producto',
      body: '¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (ok) ref.read(productsProvider.notifier).delete(product.id);
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.color = OmniColors.textPrimary,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: OmniSpacing.sm),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

// ── Drawer ─────────────────────────────────────────────────────────────────────
class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({required this.businessType});
  final String businessType;

  static const _navItems = [
    (icon: LucideIcons.home,       label: 'Inicio',          path: ''),
    (icon: LucideIcons.plusCircle, label: 'Añadir Producto', path: '/dashboard/inventory/add'),
    (icon: LucideIcons.shoppingCart, label: 'Terminal POS',  path: '/dashboard/pos'),
    (icon: LucideIcons.users,      label: 'Clientes',        path: '/dashboard/customers'),
    (icon: LucideIcons.barChart2,  label: 'Analytics',       path: '/dashboard/analytics'),
    (icon: LucideIcons.history,    label: 'Historial',       path: '/dashboard/sales/history'),
    (icon: LucideIcons.tag,        label: 'Categorías',      path: '/dashboard/categories'),
    (icon: LucideIcons.settings,   label: 'Configuración',   path: '/dashboard/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: OmniColors.bgDrawer,
      child: Column(
        children: [
          _DrawerHeader(),
          ..._navItems.map((item) => _DrawerNavItem(
            icon: item.icon,
            label: item.label,
            onTap: item.path.isEmpty
                ? () => Navigator.pop(context)
                : () { Navigator.pop(context); context.go(item.path); },
          )),
          const Spacer(),
          const Divider(color: OmniColors.borderSubtle),
          Padding(
            padding: const EdgeInsets.all(OmniSpacing.base),
            child: Text(
              'OmniBiz Automation v2.0',
              style: OmniTypography.caption.copyWith(
                color: OmniColors.textDisabled,
              ),
            ),
          ),
          const SizedBox(height: OmniSpacing.sm),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.sizeOf(context).height * 0.22;
    return Container(
      height: headerHeight.clamp(160.0, 220.0),
      width: double.infinity,
      padding: const EdgeInsets.all(OmniSpacing.xxl),
      alignment: Alignment.bottomLeft,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [OmniColors.primary, OmniColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text('OmniBiz', style: OmniTypography.displayLg),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: OmniColors.textSecondary, size: 20),
      title: Text(label, style: OmniTypography.bodyMd),
      onTap: onTap,
      dense: true,
    );
  }
}

// ── FAB ────────────────────────────────────────────────────────────────────────
class _NewSaleFab extends StatelessWidget {
  const _NewSaleFab({required this.businessType});
  final String businessType;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () =>
          context.go('/dashboard/pos?type=$businessType'),
      icon: const Icon(LucideIcons.shoppingCart),
      label: const Text('Nueva Venta'),
      backgroundColor: OmniColors.primary,
      foregroundColor: Colors.white,
    );
  }
}
