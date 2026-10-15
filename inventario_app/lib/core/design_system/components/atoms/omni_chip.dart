import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_typography.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';

/// Chip de filtro seleccionable (categorías, períodos, métodos de pago).
class OmniSelectableChip extends StatelessWidget {
  const OmniSelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  /// Contador opcional a la derecha (p. ej. productos por categoría).
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onPrimary : c.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: OmniPalette.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: OmniRadius.fullAll,
          child: AnimatedContainer(
            duration: OmniMotion.base,
            curve: OmniMotion.standard,
            height: OmniSizes.controlSm,
            padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.md + 2),
            decoration: BoxDecoration(
              color: selected ? c.primary : c.bgSurface,
              borderRadius: OmniRadius.fullAll,
              border: Border.all(
                color: selected ? c.primary : c.borderMuted,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: OmniSizes.iconSm - 2, color: fg),
                  const SizedBox(width: OmniSpacing.xs + 2),
                ],
                Text(
                  label,
                  style: context.text.label.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: OmniSpacing.xs + 2),
                  Text(
                    '$count',
                    style: context.text.caption
                        .copyWith(
                          color: selected
                              ? c.onPrimary.withAlpha(190)
                              : c.textMuted,
                        )
                        .tabular,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip eliminable (variantes de un producto).
class OmniInputChip extends StatelessWidget {
  const OmniInputChip({
    super.key,
    required this.label,
    required this.onDelete,
  });

  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.only(left: OmniSpacing.md),
      decoration: BoxDecoration(
        color: c.primaryBg,
        borderRadius: OmniRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.text.label.copyWith(
              color: c.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Quitar $label',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded,
                color: c.primaryText, size: OmniSizes.iconSm),
          ),
        ],
      ),
    );
  }
}
