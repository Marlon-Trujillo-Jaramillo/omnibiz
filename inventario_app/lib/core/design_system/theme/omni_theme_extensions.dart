import 'package:flutter/material.dart';
import '../tokens/omni_colors.dart';
import '../tokens/omni_spacing.dart';
import '../tokens/omni_radius.dart';

@immutable
class OmniThemeExt extends ThemeExtension<OmniThemeExt> {
  const OmniThemeExt({
    required this.bg,
    required this.bgSurface,
    required this.bgModal,
    required this.bgDrawer,
    required this.bgPopup,
    required this.bgPanel,
    required this.borderSubtle,
    required this.borderMuted,
    required this.borderWeak,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.primary,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color bg;
  final Color bgSurface;
  final Color bgModal;
  final Color bgDrawer;
  final Color bgPopup;
  final Color bgPanel;
  final Color borderSubtle;
  final Color borderMuted;
  final Color borderWeak;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color primary;
  final Color success;
  final Color warning;
  final Color danger;

  // Spacing shortcuts
  double get spXs   => OmniSpacing.xs;
  double get spSm   => OmniSpacing.sm;
  double get spMd   => OmniSpacing.md;
  double get spBase => OmniSpacing.base;
  double get spLg   => OmniSpacing.lg;
  double get spXl   => OmniSpacing.xl;
  double get spXxl  => OmniSpacing.xxl;
  double get spXxxl => OmniSpacing.xxxl;

  // Radius shortcuts
  double get rSm  => OmniRadius.sm;
  double get rMd  => OmniRadius.md;
  double get rLg  => OmniRadius.lg;
  double get rXl  => OmniRadius.xl;

  static const OmniThemeExt dark = OmniThemeExt(
    bg:            OmniColors.bg,
    bgSurface:     OmniColors.bgSurface,
    bgModal:       OmniColors.bgModal,
    bgDrawer:      OmniColors.bgDrawer,
    bgPopup:       OmniColors.bgPopup,
    bgPanel:       OmniColors.bgPanel,
    borderSubtle:  OmniColors.borderSubtle,
    borderMuted:   OmniColors.borderMuted,
    borderWeak:    OmniColors.borderWeak,
    textPrimary:   OmniColors.textPrimary,
    textSecondary: OmniColors.textSecondary,
    textMuted:     OmniColors.textMuted,
    textDisabled:  OmniColors.textDisabled,
    primary:       OmniColors.primary,
    success:       OmniColors.success,
    warning:       OmniColors.warning,
    danger:        OmniColors.danger,
  );

  @override
  OmniThemeExt copyWith({
    Color? bg, Color? bgSurface, Color? bgModal, Color? bgDrawer,
    Color? bgPopup, Color? bgPanel, Color? borderSubtle, Color? borderMuted,
    Color? borderWeak, Color? textPrimary, Color? textSecondary,
    Color? textMuted, Color? textDisabled, Color? primary,
    Color? success, Color? warning, Color? danger,
  }) {
    return OmniThemeExt(
      bg:            bg            ?? this.bg,
      bgSurface:     bgSurface     ?? this.bgSurface,
      bgModal:       bgModal       ?? this.bgModal,
      bgDrawer:      bgDrawer      ?? this.bgDrawer,
      bgPopup:       bgPopup       ?? this.bgPopup,
      bgPanel:       bgPanel       ?? this.bgPanel,
      borderSubtle:  borderSubtle  ?? this.borderSubtle,
      borderMuted:   borderMuted   ?? this.borderMuted,
      borderWeak:    borderWeak    ?? this.borderWeak,
      textPrimary:   textPrimary   ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted:     textMuted     ?? this.textMuted,
      textDisabled:  textDisabled  ?? this.textDisabled,
      primary:       primary       ?? this.primary,
      success:       success       ?? this.success,
      warning:       warning       ?? this.warning,
      danger:        danger        ?? this.danger,
    );
  }

  @override
  OmniThemeExt lerp(OmniThemeExt? other, double t) {
    if (other is! OmniThemeExt) return this;
    return OmniThemeExt(
      bg:            Color.lerp(bg, other.bg, t)!,
      bgSurface:     Color.lerp(bgSurface, other.bgSurface, t)!,
      bgModal:       Color.lerp(bgModal, other.bgModal, t)!,
      bgDrawer:      Color.lerp(bgDrawer, other.bgDrawer, t)!,
      bgPopup:       Color.lerp(bgPopup, other.bgPopup, t)!,
      bgPanel:       Color.lerp(bgPanel, other.bgPanel, t)!,
      borderSubtle:  Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderMuted:   Color.lerp(borderMuted, other.borderMuted, t)!,
      borderWeak:    Color.lerp(borderWeak, other.borderWeak, t)!,
      textPrimary:   Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted:     Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled:  Color.lerp(textDisabled, other.textDisabled, t)!,
      primary:       Color.lerp(primary, other.primary, t)!,
      success:       Color.lerp(success, other.success, t)!,
      warning:       Color.lerp(warning, other.warning, t)!,
      danger:        Color.lerp(danger, other.danger, t)!,
    );
  }
}

// Convenience extension for quick access
extension OmniThemeExtContext on BuildContext {
  OmniThemeExt get omni =>
      Theme.of(this).extension<OmniThemeExt>() ?? OmniThemeExt.dark;
}
