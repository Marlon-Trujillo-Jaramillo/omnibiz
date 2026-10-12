import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/presentation/providers/cart_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'customer_selector.dart';
import 'quantity_dialog.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key, required this.onCheckout});
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider.select((s) => s.items));

    return Container(
      color: OmniColors.bgPanel,
      child: Column(
        children: [
          _CartHeader(hasItems: items.isNotEmpty),
          const Divider(color: OmniColors.borderSubtle, height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: OmniSpacing.base, vertical: OmniSpacing.sm),
            child: CustomerSelector(),
          ),
          const Divider(color: OmniColors.borderSubtle, height: 1),
          Expanded(
            child: items.isEmpty
                ? OmniEmptyState(
                    icon: LucideIcons.shoppingCart,
                    title: 'Carrito vacío',
                    subtitle: 'Toca un producto para agregarlo',
                  )
                : _ItemList(items: items),
          ),
          const Divider(color: OmniColors.borderSubtle, height: 1),
          _CartSummary(itemCount: items.fold(0, (s, i) => s + i.quantity),
              onCheckout: onCheckout),
        ],
      ),
    );
  }
}

class _CartHeader extends ConsumerWidget {
  const _CartHeader({required this.hasItems});
  final bool hasItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(OmniSpacing.base),
      child: Row(
        children: [
          const Icon(LucideIcons.shoppingCart,
              color: OmniColors.textSecondary, size: 18),
          const SizedBox(width: OmniSpacing.sm),
          Text('Carrito', style: OmniTypography.headingMd),
          const Spacer(),
          if (hasItems)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Vaciar',
                  style: TextStyle(color: OmniColors.danger)),
            ),
        ],
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items});
  final List<CartItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.base, vertical: OmniSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(color: OmniColors.borderSubtle, height: 1),
      itemBuilder: (_, i) => _CartItemTile(items[i]),
    );
  }
}

// ── Cart item tile ─────────────────────────────────────────────────────────────
class _CartItemTile extends ConsumerWidget {
  const _CartItemTile(this.item);
  final CartItemEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OmniSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: OmniTypography.bodyMd,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  ref.formatMoney(item.unitPrice),
                  style: OmniTypography.caption,
                ),
              ],
            ),
          ),
          Row(
            children: [
              _QtyBtn(
                icon: Icons.remove,
                onTap: () => notifier.decrease(item.productId),
              ),
              GestureDetector(
                onTap: () async {
                  final qty = await showQuantityDialog(
                    context,
                    productName: item.productName,
                    initialValue: item.quantity,
                  );
                  if (qty != null) notifier.setQuantity(item.productId, qty);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: OmniSpacing.sm),
                  child: Text('${item.quantity}',
                      style: OmniTypography.headingSm
                          .copyWith(color: OmniColors.primary)),
                ),
              ),
              _QtyBtn(
                icon: Icons.add,
                onTap: () => notifier.increase(item.productId),
              ),
            ],
          ),
          const SizedBox(width: OmniSpacing.base),
          Flexible(
            child: Text(
              ref.formatMoney(item.totalPrice),
              style: OmniTypography.bodyMd.copyWith(
                color: OmniColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: OmniSpacing.xxl - OmniSpacing.xs,
        height: OmniSpacing.xxl - OmniSpacing.xs,
        decoration: BoxDecoration(
          color: OmniColors.borderMuted,
          borderRadius: OmniRadius.smAll,
        ),
        child: Icon(icon, size: OmniSpacing.md, color: OmniColors.textSecondary),
      ),
    );
  }
}

// ── Summary + checkout ─────────────────────────────────────────────────────────
class _CartSummary extends ConsumerWidget {
  const _CartSummary({required this.itemCount, required this.onCheckout});
  final int itemCount;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(cartProvider.select((s) => s.total));

    return Padding(
      padding: const EdgeInsets.all(OmniSpacing.base),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$itemCount artículo${itemCount != 1 ? 's' : ''}',
                  style: OmniTypography.bodySm),
              Text(
                ref.formatMoney(total),
                style:
                    OmniTypography.headingLg.copyWith(color: OmniColors.primary),
              ),
            ],
          ),
          const SizedBox(height: OmniSpacing.md),
          OmniButton(
            label: 'Cobrar',
            onPressed: itemCount == 0 ? null : onCheckout,
            fullWidth: true,
            size: OmniButtonSize.lg,
            icon: LucideIcons.creditCard,
          ),
        ],
      ),
    );
  }
}
