import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';

enum OmniButtonVariant { primary, secondary, ghost, danger }
enum OmniButtonSize { sm, md, lg }

class OmniButton extends StatelessWidget {
  const OmniButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = OmniButtonVariant.primary,
    this.size = OmniButtonSize.md,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final OmniButtonVariant variant;
  final OmniButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  VoidCallback? get _effectiveOnPressed {
    if (loading || onPressed == null) return null;
    return () {
      if (variant == OmniButtonVariant.danger) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      onPressed!();
    };
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = _effectiveOnPressed;
    final child = _buildChild();

    Widget button;
    switch (variant) {
      case OmniButtonVariant.primary:
        button = FilledButton(
          onPressed: effectiveOnPressed,
          style: _style(context),
          child: child,
        );
      case OmniButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: _style(context),
          child: child,
        );
      case OmniButtonVariant.ghost:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: _style(context),
          child: child,
        );
      case OmniButtonVariant.danger:
        button = FilledButton(
          onPressed: effectiveOnPressed,
          style: _style(context),
          child: child,
        );
    }

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildChild() {
    if (loading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == OmniButtonVariant.ghost
                ? OmniColors.primary
                : Colors.white,
          ),
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize),
          const SizedBox(width: OmniSpacing.sm),
          Text(label, style: _textStyle),
        ],
      );
    }
    return Text(label, style: _textStyle);
  }

  ButtonStyle _style(BuildContext context) {
    final padding = EdgeInsets.symmetric(
      horizontal: size == OmniButtonSize.sm
          ? OmniSpacing.md
          : size == OmniButtonSize.lg
              ? OmniSpacing.xxl
              : OmniSpacing.xl,
      vertical: size == OmniButtonSize.sm
          ? OmniSpacing.sm
          : size == OmniButtonSize.lg
              ? OmniSpacing.base
              : OmniSpacing.md,
    );

    switch (variant) {
      case OmniButtonVariant.primary:
        return FilledButton.styleFrom(
          backgroundColor: OmniColors.primary,
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: OmniRadius.mdAll),
        );
      case OmniButtonVariant.secondary:
        return OutlinedButton.styleFrom(
          foregroundColor: OmniColors.primary,
          side: const BorderSide(color: OmniColors.primary),
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: OmniRadius.mdAll),
        );
      case OmniButtonVariant.ghost:
        return TextButton.styleFrom(
          foregroundColor: OmniColors.primary,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: OmniRadius.mdAll),
        );
      case OmniButtonVariant.danger:
        return FilledButton.styleFrom(
          backgroundColor: OmniColors.danger,
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: OmniRadius.mdAll),
        );
    }
  }

  double get _iconSize => size == OmniButtonSize.sm ? 14 : 16;

  TextStyle get _textStyle {
    final base = size == OmniButtonSize.sm
        ? OmniTypography.label
        : size == OmniButtonSize.lg
            ? OmniTypography.bodyLg
            : OmniTypography.bodyMd;
    return base.copyWith(fontWeight: FontWeight.w600, color: null);
  }
}
