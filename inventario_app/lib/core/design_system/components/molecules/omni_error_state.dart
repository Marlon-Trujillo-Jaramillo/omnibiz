import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';
import '../atoms/omni_button.dart';

class OmniErrorState extends StatelessWidget {
  const OmniErrorState({
    super.key,
    this.message = 'Ocurrió un error inesperado.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

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
              decoration: const BoxDecoration(
                color: OmniColors.dangerBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                size: 40,
                color: OmniColors.danger,
              ),
            ),
            const SizedBox(height: OmniSpacing.xl),
            Text(
              'Algo salió mal',
              style: OmniTypography.headingSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OmniSpacing.sm),
            Text(
              message,
              style: OmniTypography.bodySm,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: OmniSpacing.xl),
              OmniButton(
                label: 'Reintentar',
                icon: LucideIcons.refreshCw,
                onPressed: onRetry,
                variant: OmniButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
