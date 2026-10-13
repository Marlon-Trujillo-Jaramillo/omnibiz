import 'package:flutter/material.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';

/// Contador sobre un ícono (p. ej. ítems en el carrito). Anima al cambiar.
class OmniBadge extends StatelessWidget {
  const OmniBadge({
    super.key,
    required this.count,
    required this.child,
    this.color,
  });

  final int count;
  final Widget child;
  /// Relleno del contador; por defecto, `primary`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: OmniSpacing.xxs,
          right: OmniSpacing.xxs,
          child: AnimatedScale(
            scale: count > 0 ? 1 : 0,
            duration: OmniMotion.base,
            curve: OmniMotion.emphasized,
            child: _BadgeLabel(
              count: count,
              color: color ?? context.colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeLabel extends StatelessWidget {
  const _BadgeLabel({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.xs),
      constraints: const BoxConstraints(
        minWidth: OmniSizes.iconMd - OmniSpacing.xxs,
        minHeight: OmniSizes.iconMd - OmniSpacing.xxs,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: OmniRadius.fullAll,
        border: Border.all(color: c.bg, width: OmniSizes.stroke),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: context.text.micro.copyWith(color: c.onPrimary).tabular,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Píldora de estado ("Agotado", "Al día", "Debe $…").
class OmniTag extends StatelessWidget {
  const OmniTag({
    super.key,
    required this.label,
    this.tone = OmniTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final OmniTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = c.toneFg(tone);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? OmniSpacing.sm - OmniSpacing.xxs : OmniSpacing.sm,
        vertical: dense ? OmniSpacing.xxs : OmniSpacing.xs - 1,
      ),
      decoration: BoxDecoration(
        color: c.toneBg(tone),
        borderRadius: OmniRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: OmniSizes.iconXs - 2, color: fg),
            const SizedBox(width: OmniSpacing.xs),
          ],
          Text(
            label,
            style: (dense ? context.text.caption : context.text.label)
                .copyWith(color: fg, fontWeight: FontWeight.w600)
                .tabular,
          ),
        ],
      ),
    );
  }
}
