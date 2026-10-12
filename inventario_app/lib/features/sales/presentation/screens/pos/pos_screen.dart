import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/sales/presentation/providers/cart_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'widgets/cart_panel.dart';
import 'widgets/checkout_sheet.dart';
import 'widgets/product_grid.dart';

class POSScreen extends ConsumerWidget {
  const POSScreen({super.key, this.businessContext = 'generic'});
  final String businessContext;

  void _showCheckout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CheckoutSheet(businessContext: businessContext),
      ),
    );
  }

  void _showCartSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OmniColors.bgModal,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(OmniRadius.xl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, __) => CartPanel(
          onCheckout: () {
            Navigator.pop(context);
            _showCheckout(context, ref);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide     = context.isTablet;
    final cartCount  = ref.watch(cartProvider.select((s) => s.itemCount));

    return Scaffold(
      backgroundColor: OmniColors.bg,
      appBar: AppBar(
        backgroundColor: OmniColors.bg,
        elevation: 0,
        title: Text('Terminal POS', style: OmniTypography.headingMd),
        actions: [
          if (!isWide)
            Padding(
              padding: const EdgeInsets.only(right: OmniSpacing.base),
              child: OmniBadge(
                count: cartCount,
                child: IconButton(
                  icon: const Icon(LucideIcons.shoppingCart,
                      color: OmniColors.textSecondary),
                  onPressed: () => _showCartSheet(context, ref),
                ),
              ),
            ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                const Expanded(flex: 3, child: ProductSearchAndGrid()),
                const VerticalDivider(
                    width: 1, color: OmniColors.borderSubtle),
                Expanded(
                  flex: 2,
                  child: CartPanel(
                    onCheckout: () => _showCheckout(context, ref),
                  ),
                ),
              ],
            )
          : const ProductSearchAndGrid(),
      bottomNavigationBar: isWide
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  OmniSpacing.base,
                  OmniSpacing.sm,
                  OmniSpacing.base,
                  OmniSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Consumer(builder: (_, ref, __) {
                        final total =
                            ref.watch(cartProvider.select((s) => s.total));
                        return Text(
                          'Total: ${ref.formatMoney(total)}',
                          style: OmniTypography.headingMd,
                        );
                      }),
                    ),
                    OmniButton(
                      label: 'Cobrar',
                      onPressed: cartCount > 0
                          ? () => _showCheckout(context, ref)
                          : null,
                      icon: LucideIcons.creditCard,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
