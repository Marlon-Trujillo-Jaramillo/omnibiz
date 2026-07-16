import 'package:flutter/material.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';
import '../atoms/omni_button.dart';

class OmniEmptyState extends StatelessWidget {
  const OmniEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OmniSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(OmniSpacing.xl),
              decoration: BoxDecoration(
                color: OmniColors.borderSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: OmniColors.textMuted),
            ),
            const SizedBox(height: OmniSpacing.xl),
            Text(title, style: OmniTypography.headingSm, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: OmniSpacing.sm),
              Text(
                subtitle!,
                style: OmniTypography.bodySm,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: OmniSpacing.xl),
              OmniButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: OmniButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
