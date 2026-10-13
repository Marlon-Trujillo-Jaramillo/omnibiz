import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/utils/date_formatter.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/features/inventory/presentation/providers/products_notifier.dart';
import 'package:inventario_app/features/sales/presentation/providers/sales_notifier.dart';
import 'package:inventario_app/shared/widgets/sales_chart.dart';

// ── Derived provider — computed once, shared across the subtree ────────────────
typedef _DashboardStats = ({
  bool loading,
  int todayTotal,
  int todayCount,
  int yesterdayTotal,
  int weekTotal,
  int weekCount,
  int totalStock,
  int productCount,
  List<ProductEntity> lowStock,
  int outOfStock,
});

final _dashboardStatsProvider = Provider.autoDispose<_DashboardStats>((ref) {
  final productsAsync = ref.watch(productsProvider);
  // Sólo la última semana, no todo el historial.
  final salesAsync = ref.watch(salesInRangeProvider(lastDaysRange(7)));
  final products = productsAsync.valueOrNull ?? [];
  final sales = salesAsync.valueOrNull ?? [];

  final today = lastDaysRange(1).from;
  final yesterday = lastDaysRange(2).from;
  var todayTotal = 0, todayCount = 0, yesterdayTotal = 0;
  for (final s in sales) {
    if (!s.createdAt.isBefore(today)) {
      todayTotal += s.totalAmount;
      todayCount++;
    } else if (!s.createdAt.isBefore(yesterday)) {
      yesterdayTotal += s.totalAmount;
    }
  }

  return (
    loading:
        (productsAsync.isLoading && !productsAsync.hasValue) ||
        (salesAsync.isLoading && !salesAsync.hasValue),
    todayTotal: todayTotal,
    todayCount: todayCount,
    yesterdayTotal: yesterdayTotal,
    weekTotal: sales.fold(0, (sum, s) => sum + s.totalAmount),
    weekCount: sales.length,
    totalStock: products.fold(0, (s, p) => s + p.stock),
    productCount: products.length,
    lowStock: products.where((p) => p.isLowStock && !p.isOutOfStock).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock)),
    outOfStock: products.where((p) => p.isOutOfStock).length,
  );
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.businessType});
  final String businessType;

  String get _typeLabel => switch (businessType) {
    'retail' => 'Comercio / Retail',
    'fnb' => 'Restaurante / Bar',
    _ => 'Local Comercial',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(_dashboardStatsProvider);

    final overview = <Widget>[
      _HeroKpi(stats: stats),
      const SizedBox(height: OmniSpacing.md),
      _StatGrid(stats: stats),
      const SizedBox(height: OmniSpacing.xl),
      const SalesChart(),
    ];
    final operations = <Widget>[
      const OmniSectionHeader(title: 'Accesos rápidos'),
      const SizedBox(height: OmniSpacing.md),
      _QuickActionsGrid(businessType: businessType),
      if (stats.lowStock.isNotEmpty || stats.outOfStock > 0) ...[
        const SizedBox(height: OmniSpacing.xl),
        _LowStockSection(
          products: stats.lowStock,
          outOfStock: stats.outOfStock,
        ),
      ],
      const SizedBox(height: OmniSpacing.xl),
      const _InventorySection(),
    ];

    return Scaffold(
      drawer: _DashboardDrawer(businessType: businessType),
      floatingActionButton: _NewSaleFab(businessType: businessType),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoCols = constraints.maxWidth >= OmniBreakpoints.desktop;
            final pad = constraints.maxWidth >= OmniBreakpoints.tablet
                ? OmniSpacing.xl
                : OmniSpacing.base;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(typeLabel: _typeLabel)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pad,
                    OmniSpacing.sm,
                    pad,
                    OmniSpacing.xxxl + OmniSpacing.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: twoCols
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(children: overview),
                              ),
                              const SizedBox(width: OmniSpacing.xl),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: operations,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...overview,
                              const SizedBox(height: OmniSpacing.xl),
                              ...operations,
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.typeLabel});
  final String typeLabel;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.xs,
        OmniSpacing.sm,
        OmniSpacing.sm,
        OmniSpacing.base,
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              tooltip: 'Menú',
              icon: const Icon(LucideIcons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: OmniSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: context.text.headingLg),
                const SizedBox(height: OmniSpacing.xxs),
                Text(
                  '${DateFormatter.short(DateTime.now())} · $typeLabel',
                  style: context.text.bodySm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Configuración',
            icon: Icon(LucideIcons.settings, color: c.textSecondary),
            onPressed: () => context.go('/dashboard/settings'),
          ),
        ],
      ),
    );
  }
}

// ── Hero KPI ───────────────────────────────────────────────────────────────────
class _HeroKpi extends ConsumerWidget {
  const _HeroKpi({required this.stats});
  final _DashboardStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final onBrand = c.onPrimary;
    final delta = stats.yesterdayTotal == 0
        ? null
        : (stats.todayTotal - stats.yesterdayTotal) / stats.yesterdayTotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OmniSpacing.xl),
      decoration: BoxDecoration(
        gradient: c.brandGradient,
        borderRadius: OmniRadius.xxlAll,
        boxShadow: c.glow(c.primary),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -OmniSpacing.xl,
            top: -OmniSpacing.xl,
            child: Icon(
              LucideIcons.trendingUp,
              size: OmniSizes.avatarXl * 1.6,
              color: onBrand.withAlpha(22),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.sun,
                    size: OmniSizes.iconSm,
                    color: onBrand.withAlpha(220),
                  ),
                  const SizedBox(width: OmniSpacing.sm),
                  Text(
                    'Ventas de hoy',
                    style: context.text.label.copyWith(
                      color: onBrand.withAlpha(220),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OmniSpacing.md),
              stats.loading
                  ? Container(
                      width: OmniSizes.avatarXl * 2.4,
                      height: OmniSpacing.xxxl,
                      decoration: BoxDecoration(
                        color: onBrand.withAlpha(40),
                        borderRadius: OmniRadius.mdAll,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ref.formatMoney(stats.todayTotal),
                        style: context.text.priceHero.copyWith(color: onBrand),
                      ),
                    ),
              const SizedBox(height: OmniSpacing.md),
              Wrap(
                spacing: OmniSpacing.sm,
                runSpacing: OmniSpacing.sm,
                children: [
                  _HeroPill(
                    icon: LucideIcons.receipt,
                    label:
                        '${stats.todayCount} venta${stats.todayCount == 1 ? '' : 's'}',
                  ),
                  if (delta != null)
                    _HeroPill(
                      icon: delta >= 0
                          ? LucideIcons.arrowUpRight
                          : LucideIcons.arrowDownRight,
                      label:
                          '${delta >= 0 ? '+' : ''}${(delta * 100).round()} % vs. ayer',
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final on = context.colors.onPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.sm + 2,
        vertical: OmniSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: on.withAlpha(38),
        borderRadius: OmniRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: OmniSizes.iconXs, color: on),
          const SizedBox(width: OmniSpacing.xs),
          Text(
            label,
            style: context.text.label
                .copyWith(color: on, fontWeight: FontWeight.w600)
                .tabular,
          ),
        ],
      ),
    );
  }
}

// ── Stat grid ──────────────────────────────────────────────────────────────────
class _StatGrid extends ConsumerWidget {
  const _StatGrid({required this.stats});
  final _DashboardStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final avg = stats.weekCount == 0 ? 0 : stats.weekTotal ~/ stats.weekCount;
    final cards = [
      OmniStatCard(
        title: 'Ventas 7 días',
        value: ref.formatMoneyCompact(stats.weekTotal),
        icon: LucideIcons.calendarDays,
        color: c.success,
        subtitle: '${stats.weekCount} tickets',
        onTap: () => context.go('/dashboard/analytics'),
      ),
      OmniStatCard(
        title: 'Ticket promedio',
        value: ref.formatMoneyCompact(avg),
        icon: LucideIcons.shoppingBag,
        color: c.info,
        subtitle: 'Últimos 7 días',
      ),
      OmniStatCard(
        title: 'Unidades en stock',
        value: '${stats.totalStock}',
        icon: LucideIcons.boxes,
        subtitle: '${stats.productCount} productos',
      ),
      OmniStatCard(
        title: 'Por reponer',
        value: '${stats.lowStock.length + stats.outOfStock}',
        icon: LucideIcons.alertTriangle,
        color: stats.lowStock.isEmpty && stats.outOfStock == 0
            ? c.textMuted
            : c.warning,
        subtitle: stats.outOfStock == 1
            ? '1 agotado'
            : '${stats.outOfStock} agotados',
      ),
    ];

    return LayoutBuilder(
      builder: (_, constraints) {
        final cols = constraints.maxWidth >= OmniBreakpoints.tablet ? 4 : 2;
        const gap = OmniSpacing.md;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
        if (stats.loading) {
          return OmniShimmer(
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(
                4,
                (_) => OmniSkeleton(
                  width: w,
                  height: OmniSizes.avatarXl + OmniSpacing.xxl,
                  radius: OmniRadius.lg,
                ),
              ),
            ),
          );
        }
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.businessType});
  final String businessType;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final actions = [
      (
        label: 'Vender',
        icon: LucideIcons.scanLine,
        color: c.primaryText,
        path: '/dashboard/pos?type=$businessType',
      ),
      (
        label: 'Producto',
        icon: LucideIcons.packagePlus,
        color: c.purple,
        path: '/dashboard/inventory/add',
      ),
      (
        label: 'Clientes',
        icon: LucideIcons.users,
        color: c.success,
        path: '/dashboard/customers',
      ),
      (
        label: 'Historial',
        icon: LucideIcons.history,
        color: c.orange,
        path: '/dashboard/sales/history',
      ),
      (
        label: 'Analytics',
        icon: LucideIcons.barChart3,
        color: c.info,
        path: '/dashboard/analytics',
      ),
      (
        label: 'Categorías',
        icon: LucideIcons.tags,
        color: c.teal,
        path: '/dashboard/categories',
      ),
    ];

    return LayoutBuilder(
      builder: (_, constraints) {
        final cols =
            constraints.maxWidth >= OmniBreakpoints.tablet &&
                constraints.maxWidth < OmniBreakpoints.desktop * 0.7
            ? 6
            : 3;
        const gap = OmniSpacing.md;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final a in actions)
              SizedBox(
                width: w,
                child: _ActionCard(
                  label: a.label,
                  icon: a.icon,
                  color: a.color,
                  path: a.path,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.path,
  });
  final String label;
  final IconData icon;
  final Color color;
  final String path;

  @override
  Widget build(BuildContext context) {
    return OmniCard(
      onTap: () => context.go(path),
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.sm,
        vertical: OmniSpacing.base,
      ),
      child: Column(
        children: [
          OmniIconAvatar(icon: icon, color: color, size: OmniSizes.avatarMd),
          const SizedBox(height: OmniSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.label.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Low Stock ──────────────────────────────────────────────────────────────────
class _LowStockSection extends StatelessWidget {
  const _LowStockSection({required this.products, required this.outOfStock});
  final List<ProductEntity> products;
  final int outOfStock;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OmniCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OmniSpacing.base,
              OmniSpacing.base,
              OmniSpacing.base,
              OmniSpacing.sm,
            ),
            child: OmniSectionHeader(
              leading: OmniIconAvatar(
                icon: LucideIcons.alertTriangle,
                color: c.warning,
                size: OmniSizes.avatarSm,
              ),
              title: 'Stock bajo',
              subtitle: outOfStock > 0
                  ? '${products.length} por agotarse · $outOfStock agotados'
                  : '${products.length} por agotarse',
            ),
          ),
          for (final (i, p) in products.take(5).indexed) ...[
            if (i > 0)
              const Divider(
                indent: OmniSpacing.base,
                endIndent: OmniSpacing.base,
              ),
            _LowStockRow(product: p),
          ],
          const SizedBox(height: OmniSpacing.sm),
        ],
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.product});
  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/dashboard/inventory/${product.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.base,
          vertical: OmniSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: context.text.bodyMd,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            OmniTag(
              label: '${product.stock} uds',
              tone: OmniTone.warning,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inventory ──────────────────────────────────────────────────────────────────
class _InventorySection extends ConsumerStatefulWidget {
  const _InventorySection();

  @override
  ConsumerState<_InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends ConsumerState<_InventorySection> {
  bool _showAll = false;
  static const _preview = 5;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final products = productsAsync.valueOrNull ?? const <ProductEntity>[];
    final recent = products.reversed.toList();
    final visible = _showAll ? recent : recent.take(_preview).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OmniSectionHeader(
          title: _showAll ? 'Inventario' : 'Inventario reciente',
          subtitle: products.isEmpty ? null : '${products.length} productos',
          actionLabel: products.length > _preview
              ? (_showAll ? 'Ver menos' : 'Ver todo')
              : null,
          onAction: () => setState(() => _showAll = !_showAll),
        ),
        const SizedBox(height: OmniSpacing.md),
        productsAsync.when(
          loading: () =>
              const OmniSkeletonList(count: 3, padding: EdgeInsets.zero),
          error: (_, __) => OmniErrorState(
            message: 'No se pudo cargar el inventario.',
            onRetry: () => ref.invalidate(productsProvider),
          ),
          data: (_) => products.isEmpty
              ? OmniCard(
                  child: OmniEmptyState(
                    compact: true,
                    icon: LucideIcons.packageOpen,
                    title: 'Sin productos',
                    subtitle: 'Agrega tu primer producto para comenzar',
                    actionLabel: 'Agregar producto',
                    actionIcon: LucideIcons.plus,
                    onAction: () => context.go('/dashboard/inventory/add'),
                  ),
                )
              : Column(
                  children: [
                    for (final p in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: OmniSpacing.sm),
                        child: _ProductTile(product: p),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product});
  final ProductEntity product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return OmniCard(
      onTap: () => context.go('/dashboard/inventory/${product.id}'),
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.md,
        OmniSpacing.md,
        OmniSpacing.xs,
        OmniSpacing.md,
      ),
      child: Row(
        children: [
          OmniIconAvatar(
            icon: LucideIcons.package,
            size: OmniSizes.avatarMd - OmniSpacing.xs,
            color: product.isOutOfStock
                ? c.danger
                : product.isLowStock
                ? c.warning
                : c.primaryText,
          ),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: context.text.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: OmniSpacing.xxs),
                Text(
                  '${product.category} · ${product.stock} en stock',
                  style: context.text.caption
                      .copyWith(
                        color: product.isOutOfStock
                            ? c.danger
                            : product.isLowStock
                            ? c.warning
                            : c.textMuted,
                      )
                      .tabular,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(ref.formatMoney(product.price), style: context.text.moneySm),
          _ProductMenu(product: product, ref: ref),
        ],
      ),
    );
  }
}

class _ProductMenu extends StatelessWidget {
  const _ProductMenu({required this.product, required this.ref});
  final ProductEntity product;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopupMenuButton<String>(
      tooltip: 'Opciones',
      icon: Icon(
        LucideIcons.moreVertical,
        size: OmniSizes.iconSm,
        color: c.textMuted,
      ),
      onSelected: (v) => _onSelected(context, v),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: _MenuRow(
            icon: LucideIcons.pencil,
            label: 'Editar',
            color: c.textPrimary,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            icon: LucideIcons.trash2,
            label: 'Eliminar',
            color: c.danger,
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
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: OmniSizes.iconSm, color: color),
        const SizedBox(width: OmniSpacing.md),
        Text(label, style: context.text.bodyMd.copyWith(color: color)),
      ],
    );
  }
}

// ── Drawer ─────────────────────────────────────────────────────────────────────
class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({required this.businessType});
  final String businessType;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (icon: LucideIcons.layoutDashboard, label: 'Inicio', path: ''),
      (
        icon: LucideIcons.scanLine,
        label: 'Terminal POS',
        path: '/dashboard/pos?type=$businessType',
      ),
      (
        icon: LucideIcons.packagePlus,
        label: 'Añadir producto',
        path: '/dashboard/inventory/add',
      ),
      (
        icon: LucideIcons.tags,
        label: 'Categorías',
        path: '/dashboard/categories',
      ),
      (
        icon: LucideIcons.users,
        label: 'Clientes',
        path: '/dashboard/customers',
      ),
      (
        icon: LucideIcons.history,
        label: 'Historial',
        path: '/dashboard/sales/history',
      ),
      (
        icon: LucideIcons.barChart3,
        label: 'Analytics',
        path: '/dashboard/analytics',
      ),
      (icon: LucideIcons.store, label: 'Sucursales', path: '/dashboard/stores'),
      (
        icon: LucideIcons.settings,
        label: 'Configuración',
        path: '/dashboard/settings',
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: OmniSpacing.md,
                  vertical: OmniSpacing.sm,
                ),
                children: [
                  for (final item in navItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: OmniSpacing.xxs),
                      child: ListTile(
                        selected: item.path.isEmpty,
                        leading: Icon(item.icon, size: OmniSizes.iconMd),
                        title: Text(item.label),
                        onTap: () {
                          Navigator.pop(context);
                          if (item.path.isNotEmpty) context.go(item.path);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(OmniSpacing.xl),
              child: Text(
                'OmniBiz Automation v2.0',
                style: context.text.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.xl,
        OmniSpacing.xl,
        OmniSpacing.xl,
        OmniSpacing.base,
      ),
      child: Row(
        children: [
          Container(
            width: OmniSizes.avatarMd,
            height: OmniSizes.avatarMd,
            decoration: BoxDecoration(
              gradient: c.brandGradient,
              borderRadius: OmniRadius.mdAll,
            ),
            child: Icon(
              LucideIcons.zap,
              color: c.onPrimary,
              size: OmniSizes.iconMd,
            ),
          ),
          const SizedBox(width: OmniSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OmniBiz', style: context.text.headingMd),
              Text('Punto de venta', style: context.text.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ── FAB ────────────────────────────────────────────────────────────────────────
class _NewSaleFab extends StatelessWidget {
  const _NewSaleFab({required this.businessType});
  final String businessType;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: c.brandGradient,
        borderRadius: OmniRadius.lgAll,
        boxShadow: c.glow(c.primary),
      ),
      child: FloatingActionButton.extended(
        onPressed: () => context.go('/dashboard/pos?type=$businessType'),
        backgroundColor: OmniPalette.transparent,
        icon: const Icon(LucideIcons.shoppingCart),
        label: const Text('Nueva venta'),
      ),
    );
  }
}
