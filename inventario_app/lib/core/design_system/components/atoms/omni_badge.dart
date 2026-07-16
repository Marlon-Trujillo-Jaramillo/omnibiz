import 'package:flutter/material.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';

class OmniBadge extends StatelessWidget {
  const OmniBadge({
    super.key,
    required this.count,
    required this.child,
    this.color = OmniColors.primary,
  });

  final int count;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -OmniSpacing.xs,
            right: -OmniSpacing.xs,
            child: _BadgeLabel(count: count, color: color),
          ),
      ],
    );
  }
}

class _BadgeLabel extends StatelessWidget {
  const _BadgeLabel({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.xs + 1,
        vertical: 2,
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(color: color, borderRadius: OmniRadius.fullAll),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: OmniTypography.caption.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
