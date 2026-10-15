import 'package:flutter/material.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';
import 'omni_card.dart';

/// KPI compacto: ícono tintado, valor grande (cifras tabulares) y rótulo.
class OmniStatCard extends StatelessWidget {
  const OmniStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  /// Color del ícono; por defecto, marca.
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = color ?? c.primaryText;
    return OmniCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: OmniSizes.avatarSm - OmniSpacing.xs,
                height: OmniSizes.avatarSm - OmniSpacing.xs,
                decoration: BoxDecoration(
                  color: accent.withAlpha(c.isDark ? 36 : 24),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: OmniSizes.iconSm),
              ),
              const SizedBox(width: OmniSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: context.text.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: OmniSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.text.priceLg, maxLines: 1),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: OmniSpacing.xs),
            Text(
              subtitle!,
              style: context.text.caption.tabular,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
