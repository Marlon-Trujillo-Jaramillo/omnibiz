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
    final period     = ref.watch(_periodProvider);
    final method     = ref.watch(_methodFilterProvider);
    // Filtros aplicados en la consulta: se pagina sobre el resultado filtrado.
    final query      = (from: _periodStart(period), paymentMethod: method);
    final provider   = salesHistoryProvider(query);
    final salesAsync = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de ventas')),
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
                onRetry: () => ref.invalidate(provider),
              ),
              data: (history) {
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(provider.future),
                  child: history.sales.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [_EmptyHistory(period: period)],
                        )
                      : _SalesList(
                          history: history,
                          onLoadMore: () =>
                              ref.read(provider.notifier).loadMore(),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Inicio (inclusivo) del período en días calendario; null = todo.
  /// Medianoche → clave de provider estable durante el día.
  static DateTime? _periodStart(_Period period) => switch (period) {
        _Period.all   => null,
        _Period.today => lastDaysRange(1).from,
        _Period.week  => lastDaysRange(7).from,
        _Period.month => lastDaysRange(30).from,
      };
}

// ── Filter bar ─────────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.period, required this.method});
  final _Period period;
  final String? method;

  static const _periods = [
    (label: 'Todo',   value: _Period.all),
    (label: 'Hoy',    value: _Period.today),
    (label: '7 días', value: _Period.week),
    (label: '30 días', value: _Period.month),
  ];

  static const _methods = PaymentMethods.all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              OmniSpacing.base, OmniSpacing.xs, OmniSpacing.base, 0),
          child: SegmentedButton<_Period>(
            showSelectedIcon: false,
            segments: [
              for (final p in _periods)
                ButtonSegment(value: p.value, label: Text(p.label)),
            ],
            selected: {period},
            onSelectionChanged: (s) =>
                ref.read(_periodProvider.notifier).state = s.first,
          ),
        ),
        SizedBox(
          height: OmniSizes.controlSm + OmniSpacing.xl,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: OmniSpacing.base, vertical: OmniSpacing.md),
            children: [
              OmniSelectableChip(
                label: 'Todos los métodos',
                selected: method == null,
                onTap: () =>
                    ref.read(_methodFilterProvider.notifier).state = null,
              ),
              for (final m in _methods) ...[
                const SizedBox(width: OmniSpacing.sm),
                OmniSelectableChip(
                  label: m,
                  icon: _methodIcon(m),
                  selected: method == m,
                  onTap: () =>
                      ref.read(_methodFilterProvider.notifier).state = m,
                ),
              ],
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

IconData _methodIcon(String method) => switch (method) {
      PaymentMethods.card   => LucideIcons.creditCard,
      PaymentMethods.credit => LucideIcons.notebookPen,
      _                     => LucideIcons.banknote,
    };

OmniTone _methodTone(String method) => switch (method) {
      PaymentMethods.card   => OmniTone.info,
      PaymentMethods.credit => OmniTone.warning,
      _                     => OmniTone.success,
    };

String _dayLabel(DateTime d) {
  final today = lastDaysRange(1).from;
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return 'Hoy';
  if (day == DateTime(today.year, today.month, today.day - 1)) return 'Ayer';
  return DateFormatter.date(d);
}

// ── Sales list ─────────────────────────────────────────────────────────────────
class _SalesList extends ConsumerWidget {
  const _SalesList({required this.history, required this.onLoadMore});
  final SalesHistoryState history;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = history.sales;
    // Filas: encabezado de día cuando cambia la fecha + ventas.
    final rows = <Object>[];
    String? lastDay;
    for (final s in sales) {
      final day = _dayLabel(s.createdAt);
      if (day != lastDay) {
        rows.add(day);
        lastDay = day;
      }
      rows.add(s);
    }

    return OmniResponsiveCenter(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            OmniSpacing.base, OmniSpacing.sm, OmniSpacing.base, OmniSpacing.xxl),
        itemCount: rows.length + (history.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == rows.length) {
            return Padding(
              padding: const EdgeInsets.only(top: OmniSpacing.md),
              child: OmniButton(
                label: 'Cargar más',
                icon: LucideIcons.chevronsDown,
                variant: OmniButtonVariant.secondary,
                fullWidth: true,
                loading: history.isLoadingMore,
                onPressed: history.isLoadingMore ? null : onLoadMore,
              ),
            );
          }
          final row = rows[i];
          if (row is String) {
            return Padding(
              padding: EdgeInsets.only(
                  top: i == 0 ? OmniSpacing.sm : OmniSpacing.lg,
                  bottom: OmniSpacing.sm,
                  left: OmniSpacing.xs),
              child: Text(row.toUpperCase(), style: context.text.overline),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: OmniSpacing.sm),
            child: _SaleTile(row as SaleEntity),
          );
        },
      ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final tone = _methodTone(sale.paymentMethod);
    return OmniCard(
      onTap: () => showOmniSheet(context, builder: (_) => _SaleDetailSheet(sale)),
      padding: const EdgeInsets.all(OmniSpacing.md),
      child: Row(
        children: [
          OmniIconAvatar(
            icon: _methodIcon(sale.paymentMethod),
            color: c.toneFg(tone),
            size: OmniSizes.avatarMd,
          ),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ticket #${sale.id}',
                    style: context.text.bodyMd
                        .copyWith(fontWeight: FontWeight.w600)
                        .tabular),
                const SizedBox(height: OmniSpacing.xxs),
                Text(
                  '${DateFormatter.time(sale.createdAt)} · '
                  '${sale.itemCount} artículo${sale.itemCount != 1 ? 's' : ''}',
                  style: context.text.caption.tabular,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ref.formatSaleMoney(sale.totalAmount, sale.currencyCode),
                style: context.text.moneyMd,
              ),
              const SizedBox(height: OmniSpacing.xxs),
              OmniTag(label: sale.paymentMethod, tone: tone, dense: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Detail sheet ───────────────────────────────────────────────────────────────
class _SaleDetailSheet extends ConsumerWidget {
  const _SaleDetailSheet(this.sale);
  final SaleEntity sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return OmniSheetBody(
      title: 'Ticket #${sale.id}',
      subtitle: DateFormatter.dateTime(sale.createdAt),
      trailing: OmniTag(
        label: sale.paymentMethod,
        tone: _methodTone(sale.paymentMethod),
        icon: _methodIcon(sale.paymentMethod),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OmniCard(
            color: c.bgRaised,
            child: Column(
              children: [
                for (final item in sale.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: OmniSpacing.xs),
                    child: Row(
                      children: [
                        SizedBox(
                          width: OmniSpacing.xxl + OmniSpacing.xs,
                          child: Text('${item.quantity}×',
                              style: context.text.moneySm
                                  .copyWith(color: c.textMuted)),
                        ),
                        Expanded(
                          child: Text(item.productName,
                              style: context.text.bodyMd),
                        ),
                        Text(
                          ref.formatSaleMoney(item.totalPrice, sale.currencyCode),
                          style: context.text.moneySm,
                        ),
                      ],
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: OmniSpacing.md),
                  child: Divider(),
                ),
                Row(
                  children: [
                    Text('Total', style: context.text.headingMd),
                    const Spacer(),
                    Text(
                      ref.formatSaleMoney(sale.totalAmount, sale.currencyCode),
                      style: context.text.priceLg,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: OmniSpacing.xl),
          OmniButton(
            label: 'Ver / Compartir recibo',
            icon: LucideIcons.share2,
            fullWidth: true,
            size: OmniButtonSize.lg,
            variant: OmniButtonVariant.secondary,
            onPressed: () => ReceiptService.shareReceipt(sale),
          ),
        ],
      ),
    );
  }
}
