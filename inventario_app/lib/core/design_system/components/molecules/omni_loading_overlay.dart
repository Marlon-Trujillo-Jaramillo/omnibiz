import 'package:flutter/material.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';

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
    final c = context.colors;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !isLoading,
            child: AnimatedOpacity(
              opacity: isLoading ? 1 : 0,
              duration: OmniMotion.base,
              child: ColoredBox(
                color: c.scrim,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OmniSpacing.xxl,
                      vertical: OmniSpacing.xl,
                    ),
                    decoration: BoxDecoration(
                      color: c.bgModal,
                      borderRadius: OmniRadius.xlAll,
                      border: Border.all(color: c.borderSubtle),
                      boxShadow: c.floatingShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: OmniSizes.iconXl,
                          height: OmniSizes.iconXl,
                          child: CircularProgressIndicator(
                              strokeWidth: OmniSizes.stroke + 0.5),
                        ),
                        if (label != null) ...[
                          const SizedBox(height: OmniSpacing.base),
                          Text(label!, style: context.text.bodyMd),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
