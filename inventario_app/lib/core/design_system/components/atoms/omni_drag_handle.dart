import 'package:flutter/material.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';

/// Asa de arrastre estándar en la parte superior de los bottom sheets.
class OmniDragHandle extends StatelessWidget {
  const OmniDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: OmniSpacing.xxl + OmniSpacing.sm,
        height: OmniSpacing.xs,
        decoration: BoxDecoration(
          color: context.colors.borderWeak,
          borderRadius: OmniRadius.fullAll,
        ),
      ),
    );
  }
}
