import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/error/error_mapper.dart';
import 'package:inventario_app/core/utils/app_currency.dart';
import 'package:inventario_app/core/utils/app_result.dart';
import 'package:inventario_app/features/customers/presentation/providers/customers_notifier.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/presentation/providers/cart_notifier.dart';
import 'package:inventario_app/features/sales/presentation/providers/sales_notifier.dart';
import 'package:inventario_app/features/inventory/presentation/providers/products_notifier.dart';
import 'package:inventario_app/shared/providers/database_provider.dart';
import 'package:inventario_app/core/receipt_service.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';
import 'customer_selector.dart';

final _paymentMethodProvider = StateProvider.autoDispose<String>(
  (ref) => PaymentMethods.cash,
);

class CheckoutSheet extends ConsumerWidget {
  const CheckoutSheet({super.key, required this.businessContext});
  final String businessContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(cartProvider);
    final method = ref.watch(_paymentMethodProvider);
    final selectedCustId = session.selectedCustomerId;
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final customer = selectedCustId != null
        ? customers.where((c) => c.id == selectedCustId).firstOrNull
        : null;
    final total = session.total;

    // Fiado sin cliente no es válido: si se quita el cliente, volver a Efectivo.
    ref.listen(cartProvider.select((s) => s.selectedCustomerId), (_, next) {
      if (next == null &&
          ref.read(_paymentMethodProvider) == PaymentMethods.credit) {
        ref.read(_paymentMethodProvider.notifier).state = PaymentMethods.cash;
      }
    });

    return OmniSheetBody(
      title: 'Cobrar',
      subtitle:
          '${session.itemCount} artículo${session.itemCount == 1 ? '' : 's'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TotalHero(total: total),
          const SizedBox(height: OmniSpacing.xl),
          Text('CLIENTE', style: context.text.overline),
          const SizedBox(height: OmniSpacing.sm),
          const CustomerSelector(),
          const SizedBox(height: OmniSpacing.xl),
          Text('MÉTODO DE PAGO', style: context.text.overline),
          const SizedBox(height: OmniSpacing.sm),
          _PaymentMethodSelector(
            selected: method,
            creditEnabled: customer != null,
          ),
          if (customer == null) ...[
            const SizedBox(height: OmniSpacing.sm),
            Text(
              'Para vender fiado, selecciona un cliente.',
              style: context.text.caption,
            ),
          ],
          AnimatedSize(
            duration: OmniMotion.base,
            curve: OmniMotion.standard,
            child: customer != null && method == PaymentMethods.credit
                ? Padding(
                    padding: const EdgeInsets.only(top: OmniSpacing.md),
                    child: _FiadoWarning(
                      customerName: customer.name,
                      total: total,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: OmniSpacing.xl),
          _ConfirmButton(
            total: total,
            // Defensa extra: nunca enviar Fiado si el cliente ya no está.
            method: customer == null && method == PaymentMethods.credit
                ? PaymentMethods.cash
                : method,
            businessContext: businessContext,
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _TotalHero extends ConsumerWidget {
  const _TotalHero({required this.total});
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.xl,
        vertical: OmniSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: c.primaryBg,
        borderRadius: OmniRadius.xlAll,
        border: Border.all(color: c.primary.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            'Total a cobrar',
            style: context.text.label.copyWith(color: c.primaryText),
          ),
          const SizedBox(height: OmniSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(ref.formatMoney(total), style: context.text.priceHero),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodSelector extends ConsumerWidget {
  const _PaymentMethodSelector({
    required this.selected,
    required this.creditEnabled,
  });
  final String selected;
  final bool creditEnabled;

  static IconData _icon(String m) => switch (m) {
    PaymentMethods.card => LucideIcons.creditCard,
    PaymentMethods.credit => LucideIcons.notebookPen,
    _ => LucideIcons.banknote,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(OmniSizes.controlLg, OmniSizes.controlLg),
        ),
      ),
      segments: [
        for (final m in PaymentMethods.all)
          ButtonSegment(
            value: m,
            label: Text(m),
            icon: Icon(_icon(m), size: OmniSizes.iconMd),
            enabled: m != PaymentMethods.credit || creditEnabled,
          ),
      ],
      selected: {selected},
      onSelectionChanged: (s) =>
          ref.read(_paymentMethodProvider.notifier).state = s.first,
    );
  }
}

class _FiadoWarning extends ConsumerWidget {
  const _FiadoWarning({required this.customerName, required this.total});
  final String customerName;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OmniBanner(
      tone: OmniTone.warning,
      icon: LucideIcons.notebookPen,
      title: 'Venta fiada',
      message:
          'Se sumará ${ref.formatMoney(total)} '
          'a la deuda de $customerName.',
    );
  }
}

// ── Confirm button ─────────────────────────────────────────────────────────────
class _ConfirmButton extends ConsumerStatefulWidget {
  const _ConfirmButton({
    required this.total,
    required this.method,
    required this.businessContext,
  });
  final int total;
  final String method;
  final String businessContext;

  @override
  ConsumerState<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends ConsumerState<_ConfirmButton> {
  bool _loading = false;

  Future<void> _confirm(int storeId) async {
    setState(() => _loading = true);
    try {
      final session = ref.read(cartProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final sale = _buildSale(session, storeId);
      final result = await ref.read(processSaleUseCaseProvider).execute(sale);

      result.when(
        onSuccess: (completedSale) =>
            _handleSuccess(cartNotifier, completedSale),
        onFailure: (failure) => _handleFailure(ErrorMapper.toMessage(failure)),
      );
    } catch (e) {
      _handleFailure('Error inesperado. Intenta de nuevo.');
    }
  }

  SaleEntity _buildSale(PosSessionState session, int storeId) {
    return SaleEntity(
      id: 0,
      items: session.items
          .map(
            (i) => SaleItemEntity(
              productId: i.productId,
              productName: i.productName,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
              totalPrice: i.totalPrice,
              selectedVariants: i.selectedVariants,
            ),
          )
          .toList(),
      totalAmount: widget.total,
      taxAmount: 0,
      discountAmount: 0,
      paymentMethod: widget.method,
      businessContext: widget.businessContext,
      createdAt: DateTime.now(),
      storeId: storeId,
      currencyCode: ref.read(currencyProvider).code,
      customerId: session.selectedCustomerId,
    );
  }

  void _handleFailure(String message) {
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showOmni(message, tone: OmniTone.danger);
  }

  Future<void> _handleSuccess(
    CartNotifier cartNotifier,
    SaleEntity sale,
  ) async {
    // Invalidate caches and close the UI before showing the receipt dialog.
    // The sale is already saved — receipt is best-effort and must not block recovery.
    ref.invalidate(salesInRangeProvider);
    ref.invalidate(salesHistoryProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(productsProvider);
    cartNotifier.clear();
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      // Cierra sólo los modales (sheet de cobro y, en móvil, el del carrito):
      // el cajero sigue en el POS para la siguiente venta.
      Navigator.of(context).popUntil((r) => r is! PopupRoute);
      messenger.showOmni(
        'Venta #${sale.id} registrada · ${ref.formatSaleMoney(sale.totalAmount, sale.currencyCode)}',
        tone: OmniTone.success,
      );
    }

    // Fire-and-forget: saves PDF in the background; any failure is silenced.
    ReceiptService.generateAndSaveReceipt(sale).ignore();
  }

  @override
  Widget build(BuildContext context) {
    // Sin sucursal cargada no se puede vender (nunca se escribe storeId 0).
    final storeId = ref.watch(currentStoreProvider);
    return OmniButton(
      label: 'Confirmar venta',
      variant: OmniButtonVariant.brand,
      onPressed: _loading || storeId == null ? null : () => _confirm(storeId),
      loading: _loading,
      fullWidth: true,
      size: OmniButtonSize.xl,
      icon: LucideIcons.checkCircle2,
    );
  }
}
