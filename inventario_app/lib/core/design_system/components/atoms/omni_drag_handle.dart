import 'package:flutter/material.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';

/// Standard drag handle shown at the top of bottom sheets.
class OmniDragHandle extends StatelessWidget {
  const OmniDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: OmniSpacing.xxxl,
        height: OmniSpacing.xs,
        decoration: BoxDecoration(
          color: OmniColors.borderWeak,
          borderRadius: OmniRadius.fullAll,
        ),
      ),
    );
  }
}
