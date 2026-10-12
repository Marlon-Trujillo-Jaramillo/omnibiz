import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/error/error_mapper.dart';
import 'package:inventario_app/core/error/failures.dart';
import 'package:inventario_app/core/receipt_service.dart';
import 'package:inventario_app/core/utils/date_formatter.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/presentation/providers/sales_notifier.dart';

// ── Filters ────────────────────────────────────────────────────────────────────
enum _Period { today, week, month, all }

final _periodProvider = StateProvider.autoDispose<_Period>(
    (ref) => _Period.all);
final _methodFilterProvider = StateProvider.autoDispose<String?>(
    (ref) => null);

// ── Screen ─────────────────────────────────────────────────────────────────────
class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesProvider);
    final period     = ref.watch(_periodProvider);
    final method     = ref.watch(_methodFilterProvider);

    return Scaffold(
      backgroundColor: OmniColors.bg,
      appBar: AppBar(
        backgroundColor: OmniColors.bg,
        elevation: 0,
        title: Text('Historial de ventas', style: OmniTypography.headingMd),
      ),
      body: Column(
        children: [
          _FilterBar(period: period, method: method),
          Expanded(
            child: salesAsync.when(
              loading: () => const OmniSkeletonList(),
              error: (e, _) => OmniErrorState(
                message: e is Failure
                    ? ErrorMapper.toMessage(e)
                    : 'Error al cargar el historial.',
                onRetry: () => ref.invalidate(salesProvider),
              ),
              data: (sales) {
                final filtered = _applyFilters(sales, period, method);
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(salesProvider.future),
                  color: OmniColors.primary,
                  backgroundColor: OmniColors.bgSurface,
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [_EmptyHistory(period: period)],
                        )
                      : _SalesList(sales: filtered),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static List<SaleEntity> _applyFilters(
      List<SaleEntity> sales, _Period period, String? method) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = sales.where((s) {
      if (!_matchesPeriod(s, period, today, now)) return false;
      if (method != null && s.paymentMethod != method) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  static bool _matchesPeriod(
      SaleEntity sale, _Period period, DateTime today, DateTime now) {
    return switch (period) {
      _Period.all   => true,
      _Period.today => DateTime(sale.createdAt.year, sale.createdAt.month,
              sale.createdAt.day) == today,
      _Period.week  => sale.createdAt.isAfter(now.subtract(const Duration(days: 7))),
      _Period.month => sale.createdAt.isAfter(now.subtract(const Duration(days: 30))),
    };
  }
}

// ── Filter bar ─────────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.period, required this.method});
  final _Period period;
  final String? method;

  static const _periods = [
    (label: 'Todos',  value: _Period.all),
    (label: 'Hoy',    value: _Period.today),
    (label: 'Semana', value: _Period.week),
    (label: 'Mes',    value: _Period.month),
  ];

  static const _methods = ['Efectivo', 'Tarjeta', 'Fiado'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.base, OmniSpacing.md, OmniSpacing.base, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipRow(
            children: _periods.map((p) => OmniSelectableChip(
              label: p.label,
              selected: period == p.value,
              onTap: () =>
                  ref.read(_periodProvider.notifier).state = p.value,
            )).toList(),
          ),
          const SizedBox(height: OmniSpacing.sm),
          _ChipRow(
            children: [
              OmniSelectableChip(
                label: 'Todos los métodos',
                selected: method == null,
                onTap: () =>
                    ref.read(_methodFilterProvider.notifier).state = null,
              ),
              ..._methods.map((m) => OmniSelectableChip(
                label: m,
                selected: method == m,
                onTap: () =>
                    ref.read(_methodFilterProvider.notifier).state = m,
              )),
            ],
          ),
          const SizedBox(height: OmniSpacing.md),
          const Divider(color: OmniColors.borderSubtle, height: 1),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: children
            .expand((c) => [c, const SizedBox(width: OmniSpacing.sm)])
            .toList(),
      ),
    );
  }
}

// ── Sales list ─────────────────────────────────────────────────────────────────
class _SalesList extends StatelessWidget {
  const _SalesList({required this.sales});
  final List<SaleEntity> sales;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(OmniSpacing.base),
      itemCount: sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: OmniSpacing.sm),
      itemBuilder: (_, i) => _SaleTile(sales[i]),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.period});
  final _Period period;

  @override
  Widget build(BuildContext context) {
    return OmniEmptyState(
      icon: LucideIcons.receipt,
      title: 'Sin ventas',
      subtitle: period == _Period.all
          ? 'Aún no hay ventas registradas'
          : 'No hay ventas en este período',
    );
  }
}

// ── Sale tile ──────────────────────────────────────────────────────────────────
class _SaleTile extends ConsumerWidget {
  const _SaleTile(this.sale);
  final SaleEntity sale;

  static IconData _methodIcon(String method) => switch (method) {
        'Tarjeta' => LucideIcons.creditCard,
        'Fiado'   => LucideIcons.userCheck,
        _         => LucideIcons.banknote,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(OmniSpacing.base),
        decoration: BoxDecoration(
          color: OmniColors.bgSurface,
          borderRadius: OmniRadius.mdAll,
          border: Border.all(color: OmniColors.borderSubtle),
        ),
        child: Row(
          children: [
            OmniIconAvatar(
              icon: _methodIcon(sale.paymentMethod),
              color: OmniColors.primary,
              size: 40,
            ),
            const SizedBox(width: OmniSpacing.md),
            Expanded(child: _SaleTileInfo(sale: sale)),
            Text(
              ref.formatMoney(sale.totalAmount),
              style: OmniTypography.headingSm.copyWith(
                color: OmniColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OmniColors.bgModal,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(OmniRadius.xl)),
      ),
      builder: (_) => _SaleDetailSheet(sale),
    );
  }
}

class _SaleTileInfo extends StatelessWidget {
  const _SaleTileInfo({required this.sale});
  final SaleEntity sale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ticket #${sale.id}',
          style: OmniTypography.bodyMd.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormatter.dateTime(sale.createdAt),
          style: OmniTypography.caption.copyWith(
            color: OmniColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${sale.itemCount} artículo${sale.itemCount != 1 ? 's' : ''} '
          '· ${sale.paymentMethod}',
          style: OmniTypography.caption.copyWith(color: OmniColors.textMuted),
        ),
      ],
    );
  }
}

// ── Detail sheet ───────────────────────────────────────────────────────────────
class _SaleDetailSheet extends ConsumerWidget {
  const _SaleDetailSheet(this.sale);
  final SaleEntity sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OmniResponsiveCenter(
      maxWidth: OmniBreakpoints.tablet,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          OmniSpacing.xl, OmniSpacing.xl, OmniSpacing.xl, OmniSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OmniDragHandle(),
            const SizedBox(height: OmniSpacing.base),
            _SheetHeader(sale: sale),
            const SizedBox(height: OmniSpacing.xl),
            _ItemRows(items: sale.items),
            const SizedBox(height: OmniSpacing.sm),
            const Divider(color: OmniColors.borderSubtle),
            const SizedBox(height: OmniSpacing.sm),
            _SheetTotal(sale: sale),
            const SizedBox(height: OmniSpacing.xl),
            OmniButton(
              label: 'Ver / Compartir recibo',
              icon: LucideIcons.share2,
              fullWidth: true,
              variant: OmniButtonVariant.secondary,
              onPressed: () => ReceiptService.shareReceipt(sale),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.sale});
  final SaleEntity sale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Ticket #${sale.id}', style: OmniTypography.headingLg),
        Text(
          DateFormatter.dateTime(sale.createdAt),
          style: OmniTypography.caption.copyWith(
            color: OmniColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ItemRows extends ConsumerWidget {
  const _ItemRows({required this.items});
  final List<SaleItemEntity> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: OmniSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${item.quantity}× ${item.productName}',
                style: OmniTypography.bodyMd,
              ),
            ),
            Text(
              ref.formatMoney(item.totalPrice),
              style: OmniTypography.bodyMd.copyWith(
                color: OmniColors.textSecondary,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _SheetTotal extends ConsumerWidget {
  const _SheetTotal({required this.sale});
  final SaleEntity sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: OmniTypography.headingMd),
            Text(
              ref.formatMoney(sale.totalAmount),
              style: OmniTypography.headingMd.copyWith(
                color: OmniColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: OmniSpacing.sm),
        Text(
          'Método: ${sale.paymentMethod}',
          style: OmniTypography.caption.copyWith(color: OmniColors.textMuted),
        ),
      ],
    );
  }
}
