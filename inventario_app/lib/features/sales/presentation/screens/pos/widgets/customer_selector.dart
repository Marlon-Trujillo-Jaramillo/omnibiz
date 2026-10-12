import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/utils/currency_formatter.dart';
import 'package:inventario_app/features/customers/presentation/providers/customers_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/features/sales/presentation/providers/cart_notifier.dart';

class CustomerSelector extends ConsumerWidget {
  const CustomerSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(cartProvider.select((s) => s.selectedCustomerId));
    final customers  = ref.watch(customersProvider).valueOrNull ?? [];
    final selected   = selectedId != null
        ? customers.where((c) => c.id == selectedId).firstOrNull
        : null;

    return InkWell(
      onTap: () => _showPicker(context, ref),
      borderRadius: OmniRadius.lgAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: OmniSpacing.base, vertical: OmniSpacing.md),
        decoration: BoxDecoration(
          color: OmniColors.bgSurface,
          borderRadius: OmniRadius.lgAll,
          border: Border.all(
            color: selected != null
                ? OmniColors.primary.withAlpha(50)
                : OmniColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected != null ? LucideIcons.user : LucideIcons.userPlus,
              color: selected != null ? OmniColors.primary : OmniColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: OmniSpacing.sm),
            Expanded(
              child: Text(
                selected?.name ?? 'Sin cliente (opcional)',
                style: OmniTypography.bodyMd.copyWith(
                  color: selected != null
                      ? OmniColors.textPrimary
                      : OmniColors.textDisabled,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected != null)
              GestureDetector(
                onTap: () => ref.read(cartProvider.notifier).selectCustomer(null),
                child: const Icon(LucideIcons.x,
                    color: OmniColors.textMuted, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    final customers = ref.read(customersProvider).valueOrNull ?? [];
    final currency  = ref.read(currencyProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: OmniColors.bgModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(OmniRadius.xl)),
      ),
      builder: (ctx) => Column(
        children: [
          const SizedBox(height: OmniSpacing.sm),
          const OmniDragHandle(),
          const SizedBox(height: OmniSpacing.base),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.base),
            child: Text('Seleccionar Cliente', style: OmniTypography.headingMd),
          ),
          const SizedBox(height: OmniSpacing.md),
          Expanded(
            child: customers.isEmpty
                ? OmniEmptyState(
                    icon: LucideIcons.users,
                    title: 'Sin clientes',
                    subtitle: 'Agrega clientes en la sección Clientes',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: OmniSpacing.base),
                    itemCount: customers.length,
                    itemBuilder: (_, i) {
                      final c = customers[i];
                      return ListTile(
                        leading: OmniAvatar(name: c.name),
                        title:
                            Text(c.name, style: OmniTypography.bodyMd),
                        subtitle: c.hasDebt
                            ? Text(
                                'Deuda: ${CurrencyFormatter.format(c.totalDebt, currency)}',
                                style: OmniTypography.caption
                                    .copyWith(color: OmniColors.danger),
                              )
                            : null,
                        onTap: () {
                          ref.read(cartProvider.notifier).selectCustomer(c.id);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
