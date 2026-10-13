import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/presentation/providers/cart_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'customer_selector.dart';
import 'quantity_dialog.dart';

/// Orden en curso: cliente, líneas con stepper y total + "Cobrar".
class CartPanel extends ConsumerWidget {
  const CartPanel({super.key, required this.onCheckout, this.scrollController});
  final VoidCallback onCheckout;

  /// Controlador del sheet arrastrable (móvil), para que la lista lo arrastre.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider.select((s) => s.items));
    final c = context.colors;

    return ColoredBox(
      color: c.bgPanel,
      child: Column(
        children: [
          _CartHeader(itemCount: items.fold(0, (s, i) => s + i.quantity)),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              OmniSpacing.base,
              0,
              OmniSpacing.base,
              OmniSpacing.md,
            ),
            child: CustomerSelector(),
          ),
          const Divider(),
          Expanded(
            child: items.isEmpty
                ? ListView(
                    controller: scrollController,
                    children: const [
                      OmniEmptyState(
                        compact: true,
                        icon: LucideIcons.shoppingBag,
                        title: 'Orden vacía',
                        subtitle:
                            'Toca un producto para agregarlo.\nMantén presionado para elegir la cantidad.',
                      ),
                    ],
                  )
                : _ItemList(items: items, controller: scrollController),
          ),
          _CartSummary(onCheckout: onCheckout),
        ],
      ),
    );
  }
}

class _CartHeader extends ConsumerWidget {
  const _CartHeader({required this.itemCount});
  final int itemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.base,
        OmniSpacing.base,
        OmniSpacing.sm,
        OmniSpacing.md,
      ),
      child: Row(
        children: [
          Text('Orden actual', style: context.text.headingMd),
          const SizedBox(width: OmniSpacing.sm),
          if (itemCount > 0)
            OmniTag(label: '$itemCount', tone: OmniTone.brand, dense: true),
          const Spacer(),
          if (itemCount > 0)
            TextButton.icon(
              onPressed: () async {
                final ok = await OmniConfirmDialog.show(
                  context,
                  icon: LucideIcons.trash2,
                  title: 'Vaciar orden',
                  body: 'Se quitarán todos los productos de la orden actual.',
                  confirmLabel: 'Vaciar',
                  destructive: true,
                );
                if (ok) ref.read(cartProvider.notifier).clear();
              },
              style: TextButton.styleFrom(
                foregroundColor: context.colors.danger,
              ),
              icon: const Icon(LucideIcons.trash2, size: OmniSizes.iconSm),
              label: const Text('Vaciar'),
            ),
        ],
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items, this.controller});
  final List<CartItemEntity> items;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: OmniSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(indent: OmniSpacing.base, endIndent: OmniSpacing.base),
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
    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => notifier.remove(item.productId),
      background: Container(
        color: context.colors.dangerBg,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: OmniSpacing.xl),
        child: Icon(LucideIcons.trash2, color: context.colors.danger),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.base,
          vertical: OmniSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: context.text.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: OmniSpacing.xxs),
                  Text(
                    '${ref.formatMoney(item.unitPrice)} c/u',
                    style: context.text.caption.tabular,
                  ),
                ],
              ),
            ),
            const SizedBox(width: OmniSpacing.sm),
            _Stepper(
              quantity: item.quantity,
              onDecrease: () => notifier.decrease(item.productId),
              onIncrease: () => notifier.increase(item.productId),
              onEdit: () async {
                final qty = await showQuantityDialog(
                  context,
                  productName: item.productName,
                  initialValue: item.quantity,
                );
                if (qty != null) notifier.setQuantity(item.productId, qty);
              },
            ),
            const SizedBox(width: OmniSpacing.md),
            SizedBox(
              width: OmniSizes.avatarXl + OmniSpacing.lg,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  ref.formatMoney(item.totalPrice),
                  style: context.text.moneySm,
                  textAlign: TextAlign.end,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onEdit,
  });
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: OmniSizes.controlSm,
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: OmniRadius.fullAll,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: quantity <= 1 ? LucideIcons.trash2 : LucideIcons.minus,
            color: quantity <= 1 ? c.danger : c.textSecondary,
            tooltip: quantity <= 1 ? 'Quitar' : 'Restar uno',
            onTap: onDecrease,
          ),
          InkWell(
            onTap: onEdit,
            borderRadius: OmniRadius.smAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: OmniSizes.iconLg + 4),
              child: AnimatedSwitcher(
                duration: OmniMotion.fast,
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: Text(
                  '$quantity',
                  key: ValueKey(quantity),
                  textAlign: TextAlign.center,
                  style: context.text.moneySm,
                ),
              ),
            ),
          ),
          _StepBtn(
            icon: LucideIcons.plus,
            color: c.primaryText,
            tooltip: 'Sumar uno',
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(
        width: OmniSizes.controlSm,
        height: OmniSizes.controlSm,
      ),
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      icon: Icon(icon, size: OmniSizes.iconSm, color: color),
    );
  }
}

// ── Summary + checkout ─────────────────────────────────────────────────────────
class _CartSummary extends ConsumerWidget {
  const _CartSummary({required this.onCheckout});
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final session = ref.watch(cartProvider);
    final itemCount = session.itemCount;

    return Container(
      padding: EdgeInsets.fromLTRB(
        OmniSpacing.base,
        OmniSpacing.base,
        OmniSpacing.base,
        OmniSpacing.base + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border(top: BorderSide(color: c.borderSubtle)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$itemCount artículo${itemCount != 1 ? 's' : ''}',
                style: context.text.bodySm.tabular,
              ),
              Text(
                '${session.items.length} línea${session.items.length != 1 ? 's' : ''}',
                style: context.text.caption.tabular,
              ),
            ],
          ),
          const SizedBox(height: OmniSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total', style: context.text.headingSm),
              const SizedBox(width: OmniSpacing.md),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    ref.formatMoney(session.total),
                    style: context.text.priceXl,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OmniSpacing.base),
          OmniButton(
            label: 'Cobrar',
            variant: OmniButtonVariant.brand,
            onPressed: itemCount == 0 ? null : onCheckout,
            fullWidth: true,
            size: OmniButtonSize.xl,
            icon: LucideIcons.wallet,
          ),
        ],
      ),
    );
  }
}
