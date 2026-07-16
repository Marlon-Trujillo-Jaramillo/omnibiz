import 'package:flutter/material.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';

class OmniStatCard extends StatelessWidget {
  const OmniStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = OmniColors.primary,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(OmniSpacing.base),
        decoration: BoxDecoration(
          color: OmniColors.bgSurface,
          borderRadius: OmniRadius.xlAll,
          border: Border.all(color: OmniColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBadge(icon: icon, color: color),
            const SizedBox(height: OmniSpacing.sm),
            Text(
              value,
              style: OmniTypography.headingLg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: OmniSpacing.xs),
            Text(
              title,
              style: OmniTypography.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: OmniTypography.caption.copyWith(
                  color: OmniColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OmniSpacing.xs),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: OmniSpacing.md),
    );
  }
}
