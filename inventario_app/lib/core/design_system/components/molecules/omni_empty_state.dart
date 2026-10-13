import 'package:flutter/material.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';
import '../atoms/omni_button.dart';

/// Ícono en doble halo tintado: base visual de estados vacíos y de error.
class OmniStateIllustration extends StatelessWidget {
  const OmniStateIllustration({
    super.key,
    required this.icon,
    this.tone = OmniTone.brand,
    this.compact = false,
  });

  final IconData icon;
  final OmniTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = c.toneFg(tone);
    final outer = compact ? OmniSizes.avatarXl : OmniSizes.avatarXl + OmniSpacing.xxl;
    final inner = compact ? OmniSizes.avatarLg - OmniSpacing.xs : OmniSizes.avatarXl;
    return Container(
      width: outer,
      height: outer,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fg.withAlpha(c.isDark ? 14 : 10),
      ),
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.toneBg(tone),
          border: Border.all(color: fg.withAlpha(40)),
        ),
        child: Icon(icon,
            size: compact ? OmniSizes.iconLg : OmniSizes.iconXl, color: fg),
      ),
    );
  }
}

class OmniEmptyState extends StatelessWidget {
  const OmniEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  /// Versión reducida para paneles (carrito, secciones del dashboard).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? OmniSpacing.lg : OmniSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OmniStateIllustration(icon: icon, compact: compact),
              SizedBox(height: compact ? OmniSpacing.base : OmniSpacing.xl),
              Text(
                title,
                style: compact ? context.text.headingSm : context.text.headingMd,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: OmniSpacing.sm),
                Text(
                  subtitle!,
                  style: context.text.bodySm,
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: OmniSpacing.xl),
                OmniButton(
                  label: actionLabel!,
                  icon: actionIcon,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
