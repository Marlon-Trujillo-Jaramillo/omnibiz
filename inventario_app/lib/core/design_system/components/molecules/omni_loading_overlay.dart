import 'package:flutter/material.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';

class OmniLoadingOverlay extends StatelessWidget {
  const OmniLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.label,
  });

  final bool isLoading;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OmniSpacing.xxl,
                    vertical: OmniSpacing.xl,
                  ),
                  decoration: BoxDecoration(
                    color: OmniColors.bgSurface,
                    borderRadius: OmniRadius.lgAll,
                    border: Border.all(color: OmniColors.borderSubtle),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: OmniColors.primary,
                        strokeWidth: 2.5,
                      ),
                      if (label != null) ...[
                        const SizedBox(height: OmniSpacing.base),
                        Text(label!, style: OmniTypography.bodySm),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
