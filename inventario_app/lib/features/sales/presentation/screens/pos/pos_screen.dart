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

  void _showCheckout(BuildContext context) {
    showOmniSheet(
      context,
      builder: (_) => CheckoutSheet(businessContext: businessContext),
    );
  }

  void _showCartSheet(BuildContext context) {
    showOmniSheet(
      context,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scroll) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: OmniSpacing.md),
              child: OmniDragHandle(),
            ),
            Expanded(
              child: CartPanel(
                scrollController: scroll,
                onCheckout: () {
                  Navigator.pop(sheetCtx);
                  _showCheckout(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = context.isTablet;
    final cartCount = ref.watch(cartProvider.select((s) => s.itemCount));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal POS'),
        actions: [
          if (!isWide)
            Padding(
              padding: const EdgeInsets.only(right: OmniSpacing.sm),
              child: OmniBadge(
                count: cartCount,
                child: IconButton(
                  tooltip: 'Ver orden',
                  icon: const Icon(LucideIcons.shoppingBag),
                  onPressed: () => _showCartSheet(context),
                ),
              ),
            ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                const Expanded(child: ProductSearchAndGrid()),
                Container(
                  width: OmniSizes.hairline,
                  color: context.colors.borderSubtle,
                ),
                SizedBox(
                  width: (context.screenWidth * 0.38).clamp(
                    320.0,
                    OmniSizes.sidePanel + OmniSpacing.xxxl,
                  ),
                  child: CartPanel(onCheckout: () => _showCheckout(context)),
                ),
              ],
            )
          : const ProductSearchAndGrid(),
      bottomNavigationBar: isWide
          ? null
          : _MobileCheckoutBar(
              count: cartCount,
              onOpenCart: () => _showCartSheet(context),
              onCheckout: () => _showCheckout(context),
            ),
    );
  }
}

/// Barra inferior en móvil: resumen de la orden + "Cobrar".
class _MobileCheckoutBar extends ConsumerWidget {
  const _MobileCheckoutBar({
    required this.count,
    required this.onOpenCart,
    required this.onCheckout,
  });

  final int count;
  final VoidCallback onOpenCart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final total = ref.watch(cartProvider.select((s) => s.total));
    return Container(
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border(top: BorderSide(color: c.borderSubtle)),
        boxShadow: c.floatingShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OmniSpacing.base,
            OmniSpacing.md,
            OmniSpacing.base,
            OmniSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onOpenCart,
                  borderRadius: OmniRadius.mdAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: OmniSpacing.xs,
                      horizontal: OmniSpacing.xs,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              count == 0
                                  ? 'Orden vacía'
                                  : '$count artículo${count == 1 ? '' : 's'}',
                              style: context.text.label.tabular,
                            ),
                            const SizedBox(width: OmniSpacing.xs),
                            Icon(
                              LucideIcons.chevronUp,
                              size: OmniSizes.iconXs,
                              color: c.textMuted,
                            ),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            ref.formatMoney(total),
                            style: context.text.priceLg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: OmniSpacing.md),
              OmniButton(
                label: 'Cobrar',
                variant: OmniButtonVariant.brand,
                size: OmniButtonSize.lg,
                onPressed: count > 0 ? onCheckout : null,
                icon: LucideIcons.wallet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
