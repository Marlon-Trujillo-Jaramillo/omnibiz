import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_spacing.dart';
import '../atoms/omni_button.dart';
import 'omni_empty_state.dart';

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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OmniStateIllustration(
                icon: LucideIcons.cloudOff,
                tone: OmniTone.danger,
              ),
              const SizedBox(height: OmniSpacing.xl),
              Text(
                'Algo salió mal',
                style: context.text.headingMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: OmniSpacing.sm),
              Text(
                message,
                style: context.text.bodySm,
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
      ),
    );
  }
}
