import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';

class OmniSearchBar extends StatelessWidget {
  const OmniSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Buscar...',
    this.onChanged,
    this.trailing,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OmniColors.bgSurface,
        borderRadius: OmniRadius.lgAll,
        border: Border.all(color: OmniColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: OmniSpacing.md),
            child: Icon(LucideIcons.search, color: OmniColors.textMuted, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: autofocus,
              style: OmniTypography.bodyMd.copyWith(color: OmniColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: OmniTypography.bodyMd.copyWith(
                  color: OmniColors.textDisabled,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: OmniSpacing.md,
                ),
                isDense: true,
                filled: false,
              ),
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: OmniSpacing.sm),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
