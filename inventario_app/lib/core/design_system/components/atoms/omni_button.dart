import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';
import 'omni_pressable.dart';

/// - [primary]: relleno de marca.
/// - [brand]: degradado de marca con halo — sólo para el CTA principal de la
///   pantalla ("Cobrar", "Confirmar venta").
/// - [secondary]: contorno neutro. - [ghost]: texto de marca.
/// - [danger]: relleno destructivo.
enum OmniButtonVariant { primary, brand, secondary, ghost, danger }

enum OmniButtonSize { sm, md, lg, xl }

class OmniButton extends StatelessWidget {
  const OmniButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = OmniButtonVariant.primary,
    this.size = OmniButtonSize.md,
    this.icon,
    this.trailing,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final OmniButtonVariant variant;
  final OmniButtonSize size;
  final IconData? icon;

  /// Widget al final de la etiqueta (p. ej. el total en "Cobrar").
  final Widget? trailing;
  final bool loading;
  final bool fullWidth;

  bool get _enabled => !loading && onPressed != null;

  VoidCallback? get _effectiveOnPressed {
    if (!_enabled) return null;
    return () {
      if (variant == OmniButtonVariant.danger ||
          variant == OmniButtonVariant.brand) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      onPressed!();
    };
  }

  double get _height => switch (size) {
    OmniButtonSize.sm => OmniSizes.controlSm,
    OmniButtonSize.md => OmniSizes.controlMd,
    OmniButtonSize.lg => OmniSizes.controlLg,
    OmniButtonSize.xl => OmniSizes.controlXl,
  };

  EdgeInsets get _padding => EdgeInsets.symmetric(
    horizontal: switch (size) {
      OmniButtonSize.sm => OmniSpacing.md,
      OmniButtonSize.md => OmniSpacing.lg,
      OmniButtonSize.lg => OmniSpacing.xl,
      OmniButtonSize.xl => OmniSpacing.xl,
    },
  );

  double get _iconSize => switch (size) {
    OmniButtonSize.sm => OmniSizes.iconSm,
    OmniButtonSize.md => OmniSizes.iconSm + OmniSpacing.xxs,
    _ => OmniSizes.iconMd,
  };

  TextStyle get _textStyle => switch (size) {
    OmniButtonSize.sm => OmniTypography.label,
    OmniButtonSize.md => OmniTypography.bodyMd,
    OmniButtonSize.lg => OmniTypography.bodyLg,
    OmniButtonSize.xl => OmniTypography.headingSm,
  }.copyWith(fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final colors = _colorsFor(c);
    final radius = size == OmniButtonSize.sm
        ? OmniRadius.smAll
        : OmniRadius.mdAll;
    final onTap = _effectiveOnPressed;

    final style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        variant == OmniButtonVariant.brand && _enabled
            ? OmniPalette.transparent
            : _enabled
            ? colors.bg
            : colors.disabledBg,
      ),
      foregroundColor: WidgetStatePropertyAll(
        _enabled ? colors.fg : c.textDisabled,
      ),
      overlayColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.pressed)) return colors.fg.withAlpha(30);
        if (s.contains(WidgetState.hovered)) return colors.fg.withAlpha(14);
        if (s.contains(WidgetState.focused)) return colors.fg.withAlpha(20);
        return null;
      }),
      side: WidgetStatePropertyAll(
        colors.border == null
            ? BorderSide.none
            : BorderSide(color: _enabled ? colors.border! : c.borderSubtle),
      ),
      padding: WidgetStatePropertyAll(_padding),
      minimumSize: WidgetStatePropertyAll(Size(_height, _height)),
      maximumSize: WidgetStatePropertyAll(Size(double.infinity, _height)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: radius),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(OmniPalette.transparent),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStatePropertyAll(_textStyle),
    );

    Widget button = TextButton(
      onPressed: onTap,
      style: style,
      child: _content(colors.fg),
    );

    if (variant == OmniButtonVariant.brand && _enabled) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          gradient: c.brandGradient,
          borderRadius: radius,
          boxShadow: c.glow(c.primary),
        ),
        child: button,
      );
    }

    button = OmniPressable(enabled: _enabled, child: button);
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content(Color fg) {
    final effectiveFg = _enabled ? fg : null;
    Widget child;
    if (loading) {
      child = SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: CircularProgressIndicator(
          strokeWidth: OmniSizes.stroke,
          color: fg,
        ),
      );
    } else {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _iconSize, color: effectiveFg),
            const SizedBox(width: OmniSpacing.sm),
          ],
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (trailing != null) ...[
            const SizedBox(width: OmniSpacing.md),
            trailing!,
          ],
        ],
      );
    }
    return AnimatedSwitcher(duration: OmniMotion.fast, child: child);
  }

  ({Color bg, Color fg, Color? border, Color disabledBg}) _colorsFor(
    OmniPalette c,
  ) {
    return switch (variant) {
      OmniButtonVariant.primary || OmniButtonVariant.brand => (
        bg: c.primary,
        fg: c.onPrimary,
        border: null,
        disabledBg: c.bgRaised,
      ),
      OmniButtonVariant.secondary => (
        bg: c.bgSurface,
        fg: c.textPrimary,
        border: c.borderWeak,
        disabledBg: c.bgSurface,
      ),
      OmniButtonVariant.ghost => (
        bg: OmniPalette.transparent,
        fg: c.primaryText,
        border: null,
        disabledBg: OmniPalette.transparent,
      ),
      OmniButtonVariant.danger => (
        bg: c.dangerFill,
        fg: c.onPrimary,
        border: null,
        disabledBg: c.bgRaised,
      ),
    };
  }
}
