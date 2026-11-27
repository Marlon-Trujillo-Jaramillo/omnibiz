import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/app/router/app_routes.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/utils/app_currency.dart';
import 'package:inventario_app/core/utils/currency_formatter.dart';
import 'package:inventario_app/features/settings/presentation/widgets/backup_section.dart';
import 'package:inventario_app/features/stores/presentation/providers/stores_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';
import 'package:inventario_app/shared/providers/theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentId = ref.watch(currentStoreProvider);
    final storesAsync = ref.watch(storesProvider);
    final currentStore = storesAsync.valueOrNull
        ?.where((s) => s.id == currentId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: OmniResponsiveCenter(
        maxWidth: OmniBreakpoints.tablet + OmniSpacing.xxxl * 2,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            OmniSpacing.base,
            OmniSpacing.sm,
            OmniSpacing.base,
            OmniSpacing.xxl,
          ),
          children: [
            const _SectionHeader('Apariencia'),
            OmniCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tema',
                    style: context.text.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: OmniSpacing.xxs),
                  Text(
                    '"Sistema" sigue el modo claro/oscuro del dispositivo.',
                    style: context.text.caption,
                  ),
                  const SizedBox(height: OmniSpacing.md),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistema'),
                        icon: Icon(
                          LucideIcons.monitorSmartphone,
                          size: OmniSizes.iconSm,
                        ),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Claro'),
                        icon: Icon(LucideIcons.sun, size: OmniSizes.iconSm),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Oscuro'),
                        icon: Icon(LucideIcons.moon, size: OmniSizes.iconSm),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (s) =>
                        ref.read(themeModeProvider.notifier).setMode(s.first),
                  ),
                ],
              ),
            ),
            const _SectionHeader('Sucursal'),
            _StoresTile(
              storeName: currentStore?.name ?? 'Sin sucursal',
              onTap: () => context.push(
                '${AppRoutes.dashboardBase}/${AppRoutes.stores}',
              ),
            ),
            // El respaldo a archivo (.omnibak) usa almacenamiento local que no
            // existe en el navegador; solo se muestra en la app instalada.
            if (!kIsWeb) ...[
              const _SectionHeader('Respaldo de datos'),
              const BackupSection(),
            ],
            const _SectionHeader('Moneda del sistema'),
            OmniCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, c) in AppCurrency.values.indexed) ...[
                    if (i > 0) const Divider(indent: OmniSpacing.base),
                    _CurrencyTile(
                      currency: c,
                      selected: currency == c,
                      onTap: () =>
                          _changeCurrency(context, ref, from: currency, to: c),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: OmniSpacing.md),
            const OmniBanner(tone: OmniTone.warning, message: _currencyWarning),
            const _SectionHeader('Vista previa'),
            _PreviewCard(currency: currency),
          ],
        ),
      ),
    );
  }
}

/// Los montos se guardan sin moneda (salvo las ventas): cambiarla NO
/// convierte precios ni deudas, sólo cambia cómo se muestran.
const _currencyWarning =
    'Cambiar la moneda no convierte los montos: precios, costos y deudas '
    'existentes se mostrarán con la nueva moneda sin conversión. Las ventas '
    'ya registradas conservan la moneda con la que se hicieron.';

Future<void> _changeCurrency(
  BuildContext context,
  WidgetRef ref, {
  required AppCurrency from,
  required AppCurrency to,
}) async {
  if (from == to) return;
  final ok = await OmniConfirmDialog.show(
    context,
    title: 'Cambiar moneda a ${to.code}',
    body: _currencyWarning,
    confirmLabel: 'Cambiar',
  );
  if (ok) await ref.read(currencyProvider.notifier).setCurrency(to);
}

// ── Stores tile ────────────────────────────────────────────────────────────────
class _StoresTile extends StatelessWidget {
  const _StoresTile({required this.storeName, required this.onTap});
  final String storeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OmniCard(
      onTap: onTap,
      child: Row(
        children: [
          const OmniIconAvatar(icon: LucideIcons.store),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sucursal activa', style: context.text.caption),
                const SizedBox(height: OmniSpacing.xxs),
                Text(
                  storeName,
                  style: context.text.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: OmniSizes.iconSm,
            color: context.colors.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      OmniSpacing.xs,
      OmniSpacing.xl,
      0,
      OmniSpacing.sm,
    ),
    child: Text(title.toUpperCase(), style: context.text.overline),
  );
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
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(OmniSpacing.base),
        child: Row(
          children: [
            Text(currency.flag, style: context.text.headingLg),
            const SizedBox(width: OmniSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currency.label, style: context.text.bodyMd),
                  const SizedBox(height: OmniSpacing.xxs),
                  Text(currency.code, style: context.text.caption),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: OmniMotion.base,
              child: selected
                  ? Icon(
                      LucideIcons.checkCircle2,
                      key: const ValueKey(true),
                      color: c.primaryText,
                      size: OmniSizes.iconMd,
                    )
                  : Icon(
                      LucideIcons.circle,
                      key: const ValueKey(false),
                      color: c.borderWeak,
                      size: OmniSizes.iconMd,
                    ),
            ),
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
    return OmniCard(
      child: Column(
        children: [
          _PreviewRow(
            label: 'Precio pequeño',
            value: CurrencyFormatter.format(999_000, currency),
          ),
          _PreviewRow(
            label: 'Precio mediano',
            value: CurrencyFormatter.format(12_500_000, currency),
          ),
          _PreviewRow(
            label: 'Precio grande',
            value: CurrencyFormatter.format(150_000_000, currency),
          ),
          _PreviewRow(
            label: 'Formato compacto',
            value: CurrencyFormatter.compact(250_000_000, currency),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: OmniSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.text.bodySm),
          Text(value, style: context.text.moneySm),
        ],
      ),
    );
  }
}
