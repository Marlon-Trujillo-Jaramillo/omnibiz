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
  });

  final double todayTotal;
  final double weekTotal;
  final double monthTotal;
  final double avgTicket;
  final int totalSales;
  final List<({String name, int quantity, double revenue})> topProducts;
  final double debtTotal;
  final List<CustomerEntity> debtCustomers;

  factory _AnalyticsData.from(
      List<SaleEntity> sales, List<CustomerEntity> customers) {
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    double todayTotal = 0, weekTotal = 0, monthTotal = 0;
    final Map<String, ({int qty, double rev})> productMap = {};

    for (final sale in sales) {
      final saleDay = DateTime(
          sale.createdAt.year, sale.createdAt.month, sale.createdAt.day);
      if (saleDay == today) todayTotal += sale.totalAmount;
      if (sale.createdAt.isAfter(weekAgo)) weekTotal += sale.totalAmount;
      if (sale.createdAt.isAfter(monthAgo)) monthTotal += sale.totalAmount;
      _accumulateProducts(sale.items, productMap);
    }

    final topProducts = _buildTopProducts(productMap);
    final debtCustomers = _buildDebtCustomers(customers);

    return _AnalyticsData(
      todayTotal:    todayTotal,
      weekTotal:     weekTotal,
      monthTotal:    monthTotal,
      avgTicket:     sales.isEmpty ? 0.0 : monthTotal / sales.length,
      totalSales:    sales.length,
      topProducts:   topProducts,
      debtTotal:     debtCustomers.fold(0.0, (s, c) => s + c.totalDebt),
      debtCustomers: debtCustomers.take(5).toList(),
    );
  }

  static void _accumulateProducts(
      List<SaleItemEntity> items,
      Map<String, ({int qty, double rev})> map) {
    for (final item in items) {
      final existing = map[item.productName];
      map[item.productName] = (
        qty: (existing?.qty ?? 0) + item.quantity,
        rev: (existing?.rev ?? 0.0) + item.totalPrice,
      );
    }
  }

  static List<({String name, int quantity, double revenue})> _buildTopProducts(
      Map<String, ({int qty, double rev})> map) {
    return map.entries
        .map((e) => (name: e.key, quantity: e.value.qty, revenue: e.value.rev))
        .toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity))
      ..take(5);
  }

  static List<CustomerEntity> _buildDebtCustomers(
      List<CustomerEntity> customers) {
    return customers.where((c) => c.hasDebt).toList()
      ..sort((a, b) => b.totalDebt.compareTo(a.totalDebt));
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
final _analyticsProvider = Provider.autoDispose<_AnalyticsData>((ref) {
  final sales     = ref.watch(salesProvider).valueOrNull ?? [];
  final customers = ref.watch(customersProvider).valueOrNull ?? [];
  return _AnalyticsData.from(sales, customers);
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_analyticsProvider);

    return Scaffold(
      backgroundColor: OmniColors.bg,
      appBar: AppBar(
        backgroundColor: OmniColors.bg,
        elevation: 0,
        title: Text('Analytics', style: OmniTypography.headingMd),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesProvider);
          ref.invalidate(customersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(OmniSpacing.base),
          children: [
            _SectionTitle('Resumen de ventas'),
            const SizedBox(height: OmniSpacing.md),
            _KpiGrid(data: data),
            const SizedBox(height: OmniSpacing.xl),
            _SectionTitle('Ventas (últimos 7 días)'),
            const SizedBox(height: OmniSpacing.md),
            const SalesChart(),
            const SizedBox(height: OmniSpacing.xl),
            _SectionTitle('Top 5 productos más vendidos'),
            const SizedBox(height: OmniSpacing.md),
            _TopProductsList(products: data.topProducts),
            if (data.debtCustomers.isNotEmpty) ...[
              const SizedBox(height: OmniSpacing.xl),
              _SectionTitle('Deudas de clientes'),
              const SizedBox(height: OmniSpacing.md),
              _DebtSummaryCard(data: data),
              const SizedBox(height: OmniSpacing.md),
              ...data.debtCustomers.map((c) => _DebtTile(c)),
              const SizedBox(height: OmniSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}

// ── KPI Grid ───────────────────────────────────────────────────────────────────
class _KpiGrid extends ConsumerWidget {
  const _KpiGrid({required this.data});
  final _AnalyticsData data;

  static const _kpiCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final cols = constraints.maxWidth >= OmniBreakpoints.desktop
            ? _kpiCount
            : 2;
        final items = _buildKpis(data, ref);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: OmniSpacing.sm,
            mainAxisSpacing: OmniSpacing.sm,
            childAspectRatio: 1.3,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => items[i],
        );
      },
    );
  }

  List<Widget> _buildKpis(_AnalyticsData d, WidgetRef ref) => [
    OmniStatCard(
      title: 'Hoy',
      value: ref.formatMoneyCompact(d.todayTotal),
      icon: LucideIcons.sun,
      color: OmniColors.success,
    ),
    OmniStatCard(
      title: '7 días',
      value: ref.formatMoneyCompact(d.weekTotal),
      icon: LucideIcons.calendar,
      color: OmniColors.primary,
    ),
    OmniStatCard(
      title: '30 días',
      value: ref.formatMoneyCompact(d.monthTotal),
      icon: LucideIcons.trendingUp,
      color: OmniColors.warning,
    ),
    OmniStatCard(
      title: 'Ticket prom.',
      value: ref.formatMoneyCompact(d.avgTicket),
      icon: LucideIcons.shoppingBag,
      color: OmniColors.primary,
      subtitle: '${d.totalSales} ventas totales',
    ),
  ];
}

// ── Top products ───────────────────────────────────────────────────────────────
class _TopProductsList extends StatelessWidget {
  const _TopProductsList({required this.products});
  final List<({String name, int quantity, double revenue})> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Text(
        'Sin datos de ventas',
        style: OmniTypography.bodySm.copyWith(color: OmniColors.textMuted),
      );
    }
    return Column(
      children: products.asMap().entries
          .map((e) => _TopProductTile(rank: e.key + 1, entry: e.value))
          .toList(),
    );
  }
}

class _TopProductTile extends ConsumerWidget {
  const _TopProductTile({required this.rank, required this.entry});
  final int rank;
  final ({String name, int quantity, double revenue}) entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirst = rank == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: OmniSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.base,
        vertical: OmniSpacing.md,
      ),
      decoration: BoxDecoration(
        color: OmniColors.bgSurface,
        borderRadius: OmniRadius.mdAll,
        border: Border.all(color: OmniColors.borderSubtle),
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank, highlighted: isFirst),
          const SizedBox(width: OmniSpacing.md),
          Expanded(child: _TopProductInfo(entry: entry)),
          Text(
            ref.formatMoneyCompact(entry.revenue),
            style: OmniTypography.headingSm.copyWith(
              color: OmniColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.highlighted});
  final int rank;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: OmniSpacing.xxl - OmniSpacing.xs,
      height: OmniSpacing.xxl - OmniSpacing.xs,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted
            ? OmniColors.warningBg
            : OmniColors.borderSubtle,
        shape: BoxShape.circle,
      ),
      child: Text(
        '#$rank',
        style: OmniTypography.caption.copyWith(
          color: highlighted ? OmniColors.warning : OmniColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TopProductInfo extends StatelessWidget {
  const _TopProductInfo({required this.entry});
  final ({String name, int quantity, double revenue}) entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.name, style: OmniTypography.bodyMd),
        const SizedBox(height: 2),
        Text(
          '${entry.quantity} unidades vendidas',
          style: OmniTypography.caption.copyWith(color: OmniColors.textMuted),
        ),
      ],
    );
  }
}

// ── Debt summary ───────────────────────────────────────────────────────────────
class _DebtSummaryCard extends ConsumerWidget {
  const _DebtSummaryCard({required this.data});
  final _AnalyticsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OmniStatCard(
      title: 'Deuda total',
      value: ref.formatMoney(data.debtTotal),
      icon: LucideIcons.alertCircle,
      color: OmniColors.danger,
      subtitle: '${data.debtCustomers.length} clientes con saldo',
    );
  }
}

class _DebtTile extends ConsumerWidget {
  const _DebtTile(this.customer);
  final CustomerEntity customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: OmniSpacing.sm),
      padding: const EdgeInsets.all(OmniSpacing.base),
      decoration: BoxDecoration(
        color: OmniColors.bgSurface,
        borderRadius: OmniRadius.mdAll,
        border: Border.all(color: OmniColors.borderSubtle),
      ),
      child: Row(
        children: [
          OmniAvatar(name: customer.name),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Text(customer.name, style: OmniTypography.bodyMd),
          ),
          Text(
            ref.formatMoney(customer.totalDebt),
            style: OmniTypography.headingSm.copyWith(color: OmniColors.danger),
          ),
        ],
      ),
    );
  }
}

// ── Shared ─────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: OmniTypography.headingMd);
}
