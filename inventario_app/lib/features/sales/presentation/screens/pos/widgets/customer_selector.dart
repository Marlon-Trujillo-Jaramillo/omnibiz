import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/utils/app_currency.dart';
import 'package:inventario_app/core/utils/currency_formatter.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';
import 'package:inventario_app/features/customers/presentation/providers/customers_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/features/sales/presentation/providers/cart_notifier.dart';

class CustomerSelector extends ConsumerWidget {
  const CustomerSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final selectedId = ref.watch(
      cartProvider.select((s) => s.selectedCustomerId),
    );
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final selected = selectedId != null
        ? customers.where((c) => c.id == selectedId).firstOrNull
        : null;

    return OmniCard(
      onTap: () => _showPicker(context, ref),
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.md,
        vertical: OmniSpacing.sm + 2,
      ),
      borderColor: selected != null ? c.primary.withAlpha(90) : null,
      child: Row(
        children: [
          selected != null
              ? OmniAvatar(name: selected.name, radius: OmniSizes.avatarSm / 2)
              : OmniIconAvatar(
                  icon: LucideIcons.userPlus,
                  size: OmniSizes.avatarSm,
                  color: c.textMuted,
                ),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected?.name ?? 'Cliente general',
                  style: context.text.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  selected == null
                      ? 'Toca para asignar un cliente (opcional)'
                      : selected.hasDebt
                      ? 'Debe ${ref.formatMoney(selected.totalDebt)}'
                      : 'Sin deuda',
                  style: context.text.caption
                      .copyWith(
                        color: selected?.hasDebt ?? false
                            ? c.danger
                            : c.textMuted,
                      )
                      .tabular,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (selected != null)
            IconButton(
              tooltip: 'Quitar cliente',
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  ref.read(cartProvider.notifier).selectCustomer(null),
              icon: Icon(
                LucideIcons.x,
                color: c.textMuted,
                size: OmniSizes.iconSm,
              ),
            )
          else
            Icon(
              LucideIcons.chevronRight,
              color: c.textMuted,
              size: OmniSizes.iconSm,
            ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    showOmniSheet(
      context,
      builder: (ctx) => _CustomerPicker(
        onSelect: (id) {
          ref.read(cartProvider.notifier).selectCustomer(id);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _CustomerPicker extends ConsumerStatefulWidget {
  const _CustomerPicker({required this.onSelect});
  final ValueChanged<int> onSelect;

  @override
  ConsumerState<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends ConsumerState<_CustomerPicker> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final currency = ref.watch(currencyProvider);
    final filtered = _q.isEmpty
        ? customers
        : customers
              .where(
                (c) =>
                    c.name.toLowerCase().contains(_q.toLowerCase()) ||
                    (c.phone?.contains(_q) ?? false),
              )
              .toList();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          OmniSpacing.xl,
          OmniSpacing.md,
          OmniSpacing.xl,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OmniDragHandle(),
            const SizedBox(height: OmniSpacing.lg),
            Text('Seleccionar cliente', style: context.text.headingLg),
            const SizedBox(height: OmniSpacing.base),
            if (customers.length > 5) ...[
              OmniSearchBar(
                controller: _search,
                hint: 'Buscar por nombre o teléfono',
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: OmniSpacing.md),
            ],
            Flexible(
              child: customers.isEmpty
                  ? const OmniEmptyState(
                      compact: true,
                      icon: LucideIcons.users,
                      title: 'Sin clientes',
                      subtitle: 'Agrega clientes en la sección Clientes',
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: OmniSpacing.xl),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _CustomerRow(
                        c: filtered[i],
                        currency: currency,
                        onTap: widget.onSelect,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.c,
    required this.currency,
    required this.onTap,
  });
  final CustomerEntity c;
  final AppCurrency currency;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: OmniSpacing.sm),
      leading: OmniAvatar(name: c.name),
      title: Text(
        c.name,
        style: context.text.bodyMd.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: c.phone != null
          ? Text(c.phone!, style: context.text.caption)
          : null,
      trailing: c.hasDebt
          ? OmniTag(
              label: CurrencyFormatter.format(c.totalDebt, currency),
              tone: OmniTone.danger,
              dense: true,
            )
          : null,
      onTap: () => onTap(c.id),
    );
  }
}
