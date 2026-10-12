import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/app/router/app_routes.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/utils/app_currency.dart';
import 'package:inventario_app/core/utils/currency_formatter.dart';
import 'package:inventario_app/features/stores/presentation/providers/stores_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency      = ref.watch(currencyProvider);
    final currentId     = ref.watch(currentStoreProvider);
    final storesAsync   = ref.watch(storesProvider);
    final currentStore  = storesAsync.valueOrNull
        ?.where((s) => s.id == currentId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: OmniColors.bg,
      appBar: AppBar(
        backgroundColor: OmniColors.bg,
        elevation: 0,
        title: Text('Configuración', style: OmniTypography.headingMd),
      ),
      body: OmniResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(OmniSpacing.base),
          children: [
            _SectionHeader('Sucursales'),
            const SizedBox(height: OmniSpacing.md),
            _StoresTile(
              storeName: currentStore?.name ?? 'Sin sucursal',
              onTap: () => context.push(
                '${AppRoutes.dashboardBase}/${AppRoutes.stores}',
              ),
            ),
            const SizedBox(height: OmniSpacing.xxl),
            _SectionHeader('Moneda del sistema'),
            const SizedBox(height: OmniSpacing.md),
            ...AppCurrency.values.map((c) => _CurrencyTile(
              currency: c,
              selected: currency == c,
              onTap: () => ref.read(currencyProvider.notifier).setCurrency(c),
            )),
            const SizedBox(height: OmniSpacing.xxl),
            _SectionHeader('Vista previa'),
            const SizedBox(height: OmniSpacing.md),
            _PreviewCard(currency: currency),
          ],
        ),
      ),
    );
  }
}

// ── Stores tile ────────────────────────────────────────────────────────────────
class _StoresTile extends StatelessWidget {
  const _StoresTile({required this.storeName, required this.onTap});
  final String storeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: OmniRadius.lgAll,
      child: Container(
        padding: const EdgeInsets.all(OmniSpacing.base),
        decoration: BoxDecoration(
          color: OmniColors.bgSurface,
          borderRadius: OmniRadius.lgAll,
          border: Border.all(color: OmniColors.borderSubtle),
        ),
        child: Row(
          children: [
            OmniIconAvatar(icon: LucideIcons.store, color: OmniColors.primary, size: 40),
            const SizedBox(width: OmniSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sucursal activa', style: OmniTypography.bodySm
                      .copyWith(color: OmniColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(storeName, style: OmniTypography.bodyMd),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: OmniColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: OmniTypography.headingMd);
}

// ── Currency tile ──────────────────────────────────────────────────────────────
class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.currency,
    required this.selected,
    required this.onTap,
  });
  final AppCurrency currency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: OmniSpacing.sm),
        padding: const EdgeInsets.all(OmniSpacing.base),
        decoration: BoxDecoration(
          color: selected ? OmniColors.primaryBg : OmniColors.bgSurface,
          borderRadius: OmniRadius.lgAll,
          border: Border.all(
            color: selected ? OmniColors.primary : OmniColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(currency.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: OmniSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currency.label, style: OmniTypography.bodyMd),
                  const SizedBox(height: 2),
                  Text(currency.code,
                      style: OmniTypography.caption
                          .copyWith(color: OmniColors.textMuted)),
                ],
              ),
            ),
            if (selected)
              const Icon(LucideIcons.checkCircle,
                  color: OmniColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Preview card ───────────────────────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.currency});
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OmniSpacing.base),
      decoration: BoxDecoration(
        color: OmniColors.bgSurface,
        borderRadius: OmniRadius.lgAll,
        border: Border.all(color: OmniColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Formato de precios', style: OmniTypography.label),
          const SizedBox(height: OmniSpacing.md),
          _PreviewRow(label: 'Precio pequeño',
              value: CurrencyFormatter.format(9_990, currency)),
          _PreviewRow(label: 'Precio mediano',
              value: CurrencyFormatter.format(125_000, currency)),
          _PreviewRow(label: 'Precio grande',
              value: CurrencyFormatter.format(1_500_000, currency)),
          _PreviewRow(label: 'Formato compacto',
              value: CurrencyFormatter.compact(2_500_000, currency)),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OmniSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: OmniTypography.bodySm
                  .copyWith(color: OmniColors.textSecondary)),
          Text(value,
              style:
                  OmniTypography.headingSm.copyWith(color: OmniColors.primary)),
        ],
      ),
    );
  }
}
