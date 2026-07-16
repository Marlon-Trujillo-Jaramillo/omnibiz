import 'package:flutter/material.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';

class OmniSelectableChip extends StatelessWidget {
  const OmniSelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = OmniColors.primary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.md,
          vertical: OmniSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : OmniColors.borderSubtle,
          borderRadius: OmniRadius.fullAll,
          border: Border.all(
            color: selected ? color.withAlpha(80) : OmniColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: OmniTypography.caption.copyWith(
            color: selected ? color : OmniColors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class OmniInputChip extends StatelessWidget {
  const OmniInputChip({
    super.key,
    required this.label,
    required this.onDelete,
    this.color = OmniColors.primary,
  });

  final String label;
  final VoidCallback onDelete;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: OmniSpacing.md,
        right: OmniSpacing.xs,
        top: OmniSpacing.xs,
        bottom: OmniSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: OmniRadius.fullAll,
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: OmniTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: OmniSpacing.xs),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, color: color, size: OmniSpacing.base - 2),
          ),
        ],
      ),
    );
  }
}
