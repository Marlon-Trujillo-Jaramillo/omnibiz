import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/error/error_mapper.dart';
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

final _paymentMethodProvider =
    StateProvider.autoDispose<String>((ref) => 'Efectivo');

class CheckoutSheet extends ConsumerWidget {
  const CheckoutSheet({super.key, required this.businessContext});
  final String businessContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session        = ref.watch(cartProvider);
    final method         = ref.watch(_paymentMethodProvider);
    final selectedCustId = session.selectedCustomerId;
    final customers      = ref.watch(customersProvider).valueOrNull ?? [];
    final customer       = selectedCustId != null
        ? customers.where((c) => c.id == selectedCustId).firstOrNull
        : null;
    final total   = session.total;
    final methods = ['Efectivo', 'Tarjeta', if (customer != null) 'Fiado'];

    return OmniResponsiveCenter(
      maxWidth: OmniBreakpoints.tablet,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          OmniSpacing.xl, OmniSpacing.xl, OmniSpacing.xl, OmniSpacing.xxl),
        decoration: const BoxDecoration(
          color: OmniColors.bgModal,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(OmniRadius.xl)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OmniDragHandle(),
              const SizedBox(height: OmniSpacing.base),
              Text('Cobrar', style: OmniTypography.headingLg),
              const SizedBox(height: OmniSpacing.xxl),
              _TotalHero(total: total),
              const SizedBox(height: OmniSpacing.xl),
              Text('Cliente', style: OmniTypography.headingMd),
              const SizedBox(height: OmniSpacing.md),
              const CustomerSelector(),
              const SizedBox(height: OmniSpacing.xl),
              Text('Método de pago', style: OmniTypography.headingMd),
              const SizedBox(height: OmniSpacing.md),
              _PaymentMethodRow(methods: methods, selected: method),
              if (customer != null && method == 'Fiado') ...[
                const SizedBox(height: OmniSpacing.md),
                _FiadoWarning(customerName: customer.name, total: total),
              ],
              const SizedBox(height: OmniSpacing.xxl),
              _ConfirmButton(
                total: total,
                method: method,
                businessContext: businessContext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _TotalHero extends ConsumerWidget {
  const _TotalHero({required this.total});
  final double total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text(
        ref.formatMoney(total),
        style: OmniTypography.priceHero,
      ),
    );
  }
}

class _PaymentMethodRow extends ConsumerWidget {
  const _PaymentMethodRow({required this.methods, required this.selected});
  final List<String> methods;
  final String selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: methods.map((m) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: OmniSpacing.sm),
          child: _MethodCard(
            label: m,
            selected: selected == m,
            onTap: () =>
                ref.read(_paymentMethodProvider.notifier).state = m,
          ),
        ),
      )).toList(),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.sm,
          vertical: OmniSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? OmniColors.primaryBg : OmniColors.bgSurface,
          borderRadius: OmniRadius.mdAll,
          border: Border.all(
            color: selected ? OmniColors.primary : OmniColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: OmniTypography.label.copyWith(
            color: selected ? OmniColors.primary : OmniColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _FiadoWarning extends ConsumerWidget {
  const _FiadoWarning({required this.customerName, required this.total});
  final String customerName;
  final double total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(OmniSpacing.md),
      decoration: BoxDecoration(
        color: OmniColors.dangerBg,
        borderRadius: OmniRadius.mdAll,
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, color: OmniColors.danger, size: 16),
          const SizedBox(width: OmniSpacing.sm),
          Expanded(
            child: Text(
              'Se sumará ${ref.formatMoney(total)} '
              'a la deuda de $customerName',
              style: OmniTypography.caption.copyWith(color: OmniColors.danger),
            ),
          ),
        ],
      ),
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
  final double total;
  final String method;
  final String businessContext;

  @override
  ConsumerState<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends ConsumerState<_ConfirmButton> {
  bool _loading = false;

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final session      = ref.read(cartProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final sale         = _buildSale(session);
      final result       = await ref.read(processSaleUseCaseProvider).execute(sale);

      result.when(
        onSuccess: (completedSale) => _handleSuccess(cartNotifier, completedSale),
        onFailure: (failure)       => _handleFailure(ErrorMapper.toMessage(failure)),
      );
    } catch (e) {
      _handleFailure('Error inesperado. Intenta de nuevo.');
    }
  }

  SaleEntity _buildSale(PosSessionState session) {
    return SaleEntity(
      id: 0,
      items: session.items.map((i) => SaleItemEntity(
        productId:        i.productId,
        productName:      i.productName,
        quantity:         i.quantity,
        unitPrice:        i.unitPrice,
        totalPrice:       i.totalPrice,
        selectedVariants: i.selectedVariants,
      )).toList(),
      totalAmount:     widget.total,
      taxAmount:       0,
      discountAmount:  0,
      paymentMethod:   widget.method,
      businessContext: widget.businessContext,
      createdAt:       DateTime.now(),
      storeId:         ref.read(currentStoreProvider) ?? 0,
      customerId:      session.selectedCustomerId,
    );
  }

  void _handleFailure(String message) {
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: OmniColors.danger),
    );
  }

  Future<void> _handleSuccess(CartNotifier cartNotifier, dynamic sale) async {
    // Invalidate caches and close the UI before showing the receipt dialog.
    // The sale is already saved — receipt is best-effort and must not block recovery.
    ref.invalidate(salesProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(productsProvider);
    cartNotifier.clear();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);

    // Fire-and-forget: saves PDF in the background; any failure is silenced.
    ReceiptService.generateAndSaveReceipt(sale).ignore();
  }

  @override
  Widget build(BuildContext context) {
    return OmniButton(
      label: 'Confirmar venta',
      onPressed: _loading ? null : _confirm,
      loading: _loading,
      fullWidth: true,
      size: OmniButtonSize.lg,
      icon: LucideIcons.checkCircle,
    );
  }
}
