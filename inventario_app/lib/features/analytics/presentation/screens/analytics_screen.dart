import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/features/customers/presentation/providers/customers_notifier.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/presentation/providers/sales_notifier.dart';
import 'package:inventario_app/shared/widgets/sales_chart.dart';

// ── Analytics data model ───────────────────────────────────────────────────────
class _AnalyticsData {
  const _AnalyticsData({
    required this.todayTotal,
    required this.weekTotal,
    required this.monthTotal,
    required this.avgTicket,
    required this.totalSales,
    required this.topProducts,
    required this.debtTotal,
    required this.debtCustomers,
    required this.debtCount,
  });

  // Montos en centavos.
  final int todayTotal;
  final int weekTotal;
  final int monthTotal;
  final int avgTicket;
  final int totalSales;
  final List<({String name, int quantity, int revenue})> topProducts;
  final int debtTotal;
  final List<CustomerEntity> debtCustomers;
  /// Total de clientes con saldo (no sólo los 5 que se listan).
  final int debtCount;

  /// [sales] = ventas de los últimos 30 días (ver [_monthRange]).
  factory _AnalyticsData.from(
      List<SaleEntity> sales, List<CustomerEntity> customers) {
    final now      = DateTime.now();
    final today    = lastDaysRange(1, now: now).from;
    final weekFrom = lastDaysRange(7, now: now).from;

    int todayTotal = 0, weekTotal = 0, monthTotal = 0;
    final Map<String, ({int qty, int rev})> productMap = {};

    for (final sale in sales) {
      if (!sale.createdAt.isBefore(today)) todayTotal += sale.totalAmount;
      if (!sale.createdAt.isBefore(weekFrom)) weekTotal += sale.totalAmount;
      monthTotal += sale.totalAmount;
      _accumulateProducts(sale.items, productMap);
    }

    final topProducts = _buildTopProducts(productMap);
    final debtCustomers = _buildDebtCustomers(customers);

    return _AnalyticsData(
      todayTotal:    todayTotal,
      weekTotal:     weekTotal,
      monthTotal:    monthTotal,
      avgTicket:     sales.isEmpty ? 0 : (monthTotal / sales.length).round(),
      totalSales:    sales.length,
      topProducts:   topProducts,
      debtTotal:     debtCustomers.fold(0, (s, c) => s + c.totalDebt),
      debtCustomers: debtCustomers.take(5).toList(),
      debtCount:     debtCustomers.length,
    );
  }

  static void _accumulateProducts(
      List<SaleItemEntity> items,
      Map<String, ({int qty, int rev})> map) {
    for (final item in items) {
      final existing = map[item.productName];
      map[item.productName] = (
        qty: (existing?.qty ?? 0) + item.quantity,
        rev: (existing?.rev ?? 0) + item.totalPrice,
      );
    }
  }

  static List<({String name, int quantity, int revenue})> _buildTopProducts(
      Map<String, ({int qty, int rev})> map) {
    final sorted = map.entries
        .map((e) => (name: e.key, quantity: e.value.qty, revenue: e.value.rev))
        .toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    // Antes: `..take(5)` en cascada no recortaba nada (devolvía todos).
    return sorted.take(5).toList();
  }

  static List<CustomerEntity> _buildDebtCustomers(
      List<CustomerEntity> customers) {
    return customers.where((c) => c.hasDebt).toList()
      ..sort((a, b) => b.totalDebt.compareTo(a.totalDebt));
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
SalesRange _monthRange() => lastDaysRange(30);

final _analyticsProvider = Provider.autoDispose<_AnalyticsData>((ref) {
  final sales     =
      ref.watch(salesInRangeProvider(_monthRange())).valueOrNull ?? [];
  final customers = ref.watch(customersProvider).valueOrNull ?? [];
  return _AnalyticsData.from(sales, customers);
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_analyticsProvider);
    final salesAsync = ref.watch(salesInRangeProvider(_monthRange()));
    final loading = salesAsync.isLoading && !salesAsync.hasValue;

    Widget body;
    if (salesAsync.hasError && !salesAsync.hasValue) {
      body = OmniErrorState(
        message: 'No se pudieron cargar las ventas.',
        onRetry: () => ref.invalidate(salesInRangeProvider),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesInRangeProvider);
          ref.invalidate(customersProvider);
        },
        child: OmniResponsiveCenter(
          maxWidth: OmniBreakpoints.desktop + OmniSpacing.xxxl * 4,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(OmniSpacing.base, OmniSpacing.sm,
                OmniSpacing.base, OmniSpacing.xxl),
            children: [
              Text('RESUMEN · 30 DÍAS', style: context.text.overline),
              const SizedBox(height: OmniSpacing.md),
              loading
                  ? const _KpiSkeleton()
                  : _KpiGrid(data: data),
              const SizedBox(height: OmniSpacing.xl),
              const SalesChart(),
              const SizedBox(height: OmniSpacing.xl),
              LayoutBuilder(builder: (_, constraints) {
                final top = _Panel(
                  title: 'Más vendidos',
                  subtitle: 'Top 5 por unidades · 30 días',
                  icon: LucideIcons.trophy,
                  child: loading
                      ? const OmniSkeletonList(count: 3, padding: EdgeInsets.zero)
                      : _TopProductsList(products: data.topProducts),
                );
                final debts = _Panel(
                  title: 'Cuentas por cobrar',
                  subtitle: data.debtCount == 0
                      ? 'Nadie debe nada'
                      : '${data.debtCount} cliente${data.debtCount == 1 ? '' : 's'} con saldo',
                  icon: LucideIcons.notebookPen,
                  child: _DebtSection(data: data),
                );
                if (constraints.maxWidth >= OmniBreakpoints.desktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: top),
                      const SizedBox(width: OmniSpacing.base),
                      Expanded(child: debts),
                    ],
                  );
                }
                return Column(children: [
                  top,
                  const SizedBox(height: OmniSpacing.base),
                  debts,
                ]);
              }),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: body,
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OmniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OmniSectionHeader(
            leading: OmniIconAvatar(icon: icon, size: OmniSizes.avatarSm),
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: OmniSpacing.base),
          child,
        ],
      ),
    );
  }
}

// ── KPI Grid ───────────────────────────────────────────────────────────────────
List<Widget> _wrapGrid(BoxConstraints constraints, List<Widget> items) {
  final cols = constraints.maxWidth >= OmniBreakpoints.tablet ? 4 : 2;
  const gap = OmniSpacing.md;
  final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
  return [for (final i in items) SizedBox(width: w, child: i)];
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => OmniShimmer(
        child: Wrap(
          spacing: OmniSpacing.md,
          runSpacing: OmniSpacing.md,
          children: _wrapGrid(constraints, [
            for (var i = 0; i < 4; i++)
              const OmniSkeleton(
                  height: OmniSizes.avatarXl + OmniSpacing.xxl,
                  radius: OmniRadius.lg),
          ]),
        ),
      ),
    );
  }
}

class _KpiGrid extends ConsumerWidget {
  const _KpiGrid({required this.data});
  final _AnalyticsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = [
      OmniStatCard(
        title: 'Hoy',
        value: ref.formatMoneyCompact(data.todayTotal),
        icon: LucideIcons.sun,
        color: c.success,
      ),
      OmniStatCard(
        title: '7 días',
        value: ref.formatMoneyCompact(data.weekTotal),
        icon: LucideIcons.calendarDays,
        color: c.info,
      ),
      OmniStatCard(
        title: '30 días',
        value: ref.formatMoneyCompact(data.monthTotal),
        icon: LucideIcons.trendingUp,
      ),
      OmniStatCard(
        title: 'Ticket promedio',
        value: ref.formatMoneyCompact(data.avgTicket),
        icon: LucideIcons.shoppingBag,
        color: c.purple,
        subtitle: '${data.totalSales} ventas en 30 días',
      ),
    ];
    return LayoutBuilder(
      builder: (_, constraints) => Wrap(
        spacing: OmniSpacing.md,
        runSpacing: OmniSpacing.md,
        children: _wrapGrid(constraints, items),
      ),
    );
  }
}

// ── Top products ───────────────────────────────────────────────────────────────
class _TopProductsList extends ConsumerWidget {
  const _TopProductsList({required this.products});
  final List<({String name, int quantity, int revenue})> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    if (products.isEmpty) {
      return const OmniEmptyState(
        compact: true,
        icon: LucideIcons.barChart3,
        title: 'Sin datos de ventas',
        subtitle: 'Cuando vendas, aquí verás tus productos estrella.',
      );
    }
    final maxQty = products.first.quantity;
    return Column(
      children: [
        for (final (i, p) in products.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: OmniSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    _RankBadge(rank: i + 1),
                    const SizedBox(width: OmniSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: context.text.bodyMd
                                  .copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                          Text('${p.quantity} unidades',
                              style: context.text.caption.tabular),
                        ],
                      ),
                    ),
                    Text(ref.formatMoneyCompact(p.revenue),
                        style: context.text.moneySm),
                  ],
                ),
                const SizedBox(height: OmniSpacing.sm),
                ClipRRect(
                  borderRadius: OmniRadius.fullAll,
                  child: LinearProgressIndicator(
                    value: maxQty == 0 ? 0 : p.quantity / maxQty,
                    minHeight: OmniSpacing.xs + 2,
                    color: i == 0 ? c.primary : c.primary.withAlpha(140),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final first = rank == 1;
    return Container(
      width: OmniSizes.avatarSm - OmniSpacing.xs,
      height: OmniSizes.avatarSm - OmniSpacing.xs,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: first ? c.brandGradient : null,
        color: first ? null : c.bgRaised,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: context.text.label.copyWith(
          color: first ? c.onPrimary : c.textSecondary,
          fontWeight: FontWeight.w700,
        ).tabular,
      ),
    );
  }
}

// ── Debts ──────────────────────────────────────────────────────────────────────
class _DebtSection extends ConsumerWidget {
  const _DebtSection({required this.data});
  final _AnalyticsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    if (data.debtCustomers.isEmpty) {
      return const OmniEmptyState(
        compact: true,
        icon: LucideIcons.checkCircle2,
        title: 'Todo al día',
        subtitle: 'No hay ventas fiadas pendientes.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(OmniSpacing.base),
          decoration: BoxDecoration(
            color: c.dangerBg,
            borderRadius: OmniRadius.mdAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deuda total',
                  style: context.text.label.copyWith(color: c.danger)),
              const SizedBox(height: OmniSpacing.xxs),
              Text(ref.formatMoney(data.debtTotal),
                  style: context.text.priceLg.copyWith(color: c.danger)),
            ],
          ),
        ),
        const SizedBox(height: OmniSpacing.md),
        for (final cust in data.debtCustomers)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: OmniSpacing.xs + 2),
            child: Row(
              children: [
                OmniAvatar(name: cust.name, radius: OmniSizes.avatarSm / 2),
                const SizedBox(width: OmniSpacing.md),
                Expanded(
                  child: Text(cust.name,
                      style: context.text.bodyMd,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(ref.formatMoney(cust.totalDebt),
                    style: context.text.moneySm.copyWith(color: c.danger)),
              ],
            ),
          ),
      ],
    );
  }
}
