import 'package:flutter/material.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';
import '../atoms/omni_pressable.dart';

/// Superficie base: tarjeta con borde suave (y sombra leve en claro).
/// Con [onTap] se vuelve interactiva con ripple y hundimiento al presionar.
class OmniCard extends StatelessWidget {
  const OmniCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(OmniSpacing.base),
    this.color,
    this.borderColor,
    this.radius,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? radius;

  /// Resalta con tinte y borde de marca.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = radius ?? OmniRadius.lgAll;
    final interactive = onTap != null || onLongPress != null;

    Widget card = AnimatedContainer(
      duration: OmniMotion.base,
      decoration: BoxDecoration(
        color: selected ? c.primaryBg : (color ?? c.bgSurface),
        borderRadius: r,
        border: Border.all(
          color: selected ? c.primary : (borderColor ?? c.borderSubtle),
          width: selected ? OmniSizes.focusRing : OmniSizes.hairline,
        ),
        boxShadow: selected ? null : c.cardShadow,
      ),
      child: Material(
        color: OmniPalette.transparent,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: interactive
            ? InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                borderRadius: r,
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );

    if (interactive) card = OmniPressable(scale: 0.985, child: card);
    return card;
  }
}

/// Título de sección con acción opcional ("Ver todo").
class OmniSectionHeader extends StatelessWidget {
  const OmniSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: OmniSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.headingSm),
              if (subtitle != null) ...[
                const SizedBox(height: OmniSpacing.xxs),
                Text(subtitle!, style: context.text.caption),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
