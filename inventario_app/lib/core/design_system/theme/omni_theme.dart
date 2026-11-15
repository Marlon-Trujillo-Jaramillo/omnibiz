import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import '../tokens/omni_colors.dart';
import '../tokens/omni_radius.dart';
import '../tokens/omni_sizes.dart';
import '../tokens/omni_spacing.dart';
import '../tokens/omni_typography.dart';

/// Temas claro y oscuro con la misma identidad. Todo sale de [OmniPalette].
abstract final class OmniTheme {
  static ThemeData dark() => _build(OmniPalette.dark);
  static ThemeData light() => _build(OmniPalette.light);

  static ThemeData _build(OmniPalette p) {
    final text = OmniTypography.textTheme(p);
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryBg,
      onPrimaryContainer: p.primaryText,
      secondary: p.brandEnd,
      onSecondary: p.onPrimary,
      secondaryContainer: p.primaryBg,
      onSecondaryContainer: p.primaryText,
      tertiary: p.teal,
      onTertiary: p.onPrimary,
      error: p.danger,
      onError: p.onPrimary,
      errorContainer: p.dangerBg,
      onErrorContainer: p.danger,
      surface: p.bgSurface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceDim: p.bg,
      surfaceBright: p.bgRaised,
      surfaceContainerLowest: p.bg,
      surfaceContainerLow: p.bgPanel,
      surfaceContainer: p.bgSurface,
      surfaceContainerHigh: p.bgRaised,
      surfaceContainerHighest: p.bgPopup,
      outline: p.borderWeak,
      outlineVariant: p.borderSubtle,
      shadow: p.shadow,
      scrim: p.scrim,
      inverseSurface: p.snackBg,
      onInverseSurface: p.onSnack,
      inversePrimary: p.primaryText,
      surfaceTint: OmniPalette.transparent,
    );

    final controlShape = RoundedRectangleBorder(borderRadius: OmniRadius.mdAll);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: OmniSpacing.xl,
      vertical: OmniSpacing.md,
    );
    const buttonMinSize = Size(OmniSizes.controlMd, OmniSizes.controlMd);
    final buttonText = text.labelLarge;

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      fontFamily: OmniTypography.fontFamily,
      textTheme: text,
      primaryTextTheme: text,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [p],

      // ── Navegación ─────────────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.textPrimary,
        surfaceTintColor: OmniPalette.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: OmniSpacing.base,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(
          color: p.textSecondary,
          size: OmniSizes.iconMd,
        ),
        actionsIconTheme: IconThemeData(
          color: p.textSecondary,
          size: OmniSizes.iconMd,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.bgPanel,
        surfaceTintColor: OmniPalette.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(OmniRadius.xxl),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.bgPanel,
        indicatorColor: p.primaryBg,
        surfaceTintColor: OmniPalette.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium!.copyWith(
            color: s.contains(WidgetState.selected)
                ? p.primaryText
                : p.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? p.primaryText
                : p.textMuted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.bgPanel,
        indicatorColor: p.primaryBg,
        selectedIconTheme: IconThemeData(color: p.primaryText),
        unselectedIconTheme: IconThemeData(color: p.textMuted),
        selectedLabelTextStyle: text.labelMedium!.copyWith(
          color: p.primaryText,
        ),
        unselectedLabelTextStyle: text.labelMedium!.copyWith(
          color: p.textMuted,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        titleTextStyle: text.bodyMedium,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: OmniRadius.mdAll),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.base,
        ),
        selectedColor: p.primaryText,
        selectedTileColor: p.primaryBg,
      ),

      // ── Superficies ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: p.bgSurface,
        surfaceTintColor: OmniPalette.transparent,
        shadowColor: p.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: OmniRadius.lgAll,
          side: BorderSide(color: p.borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.bgModal,
        surfaceTintColor: OmniPalette.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: OmniRadius.xxlAll,
          side: p.isDark ? BorderSide(color: p.borderSubtle) : BorderSide.none,
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium!.copyWith(color: p.textSecondary),
        barrierColor: p.scrim,
        insetPadding: const EdgeInsets.all(OmniSpacing.xl),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.bgModal,
        modalBackgroundColor: p.bgModal,
        surfaceTintColor: OmniPalette.transparent,
        modalBarrierColor: p.scrim,
        shape: const RoundedRectangleBorder(borderRadius: OmniRadius.sheetTop),
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: p.borderWeak,
        clipBehavior: Clip.antiAlias,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.bgPopup,
        surfaceTintColor: OmniPalette.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: OmniRadius.mdAll,
          side: BorderSide(color: p.borderSubtle),
        ),
        elevation: p.isDark ? 0 : 8,
        shadowColor: p.shadow,
        textStyle: text.bodyMedium,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.bgPopup),
          surfaceTintColor: const WidgetStatePropertyAll(
            OmniPalette.transparent,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: OmniRadius.mdAll,
              side: BorderSide(color: p.borderSubtle),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.bodyMedium,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.bgPopup),
          surfaceTintColor: const WidgetStatePropertyAll(
            OmniPalette.transparent,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.snackBg,
          borderRadius: OmniRadius.smAll,
        ),
        textStyle: text.labelMedium!.copyWith(color: p.onSnack),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.snackBg,
        contentTextStyle: text.bodyMedium!.copyWith(color: p.onSnack),
        actionTextColor: OmniPalette.dark.primaryText,
        shape: RoundedRectangleBorder(borderRadius: OmniRadius.lgAll),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(
          OmniSpacing.base,
          0,
          OmniSpacing.base,
          OmniSpacing.base,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.borderSubtle,
        thickness: OmniSizes.hairline,
        space: 0,
      ),

      // ── Botones ────────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.bgRaised,
          disabledForegroundColor: p.textDisabled,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          shape: controlShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.bgRaised,
          foregroundColor: p.textPrimary,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          shape: controlShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          disabledForegroundColor: p.textDisabled,
          side: BorderSide(color: p.borderWeak),
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primaryText,
          disabledForegroundColor: p.textDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: OmniSpacing.md,
            vertical: OmniSpacing.sm,
          ),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.textSecondary,
          disabledForegroundColor: p.textDisabled,
          highlightColor: p.primaryBg,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: buttonText,
        shape: RoundedRectangleBorder(borderRadius: OmniRadius.lgAll),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        selectedIcon: const Icon(Icons.check_rounded, size: OmniSizes.iconSm),
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(OmniSizes.controlMd, OmniSizes.controlMd),
          ),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          shape: WidgetStatePropertyAll(controlShape),
          side: WidgetStatePropertyAll(BorderSide(color: p.borderMuted)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.primaryBg : p.bgSurface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return p.textDisabled;
            return s.contains(WidgetState.selected)
                ? p.primaryText
                : p.textSecondary;
          }),
          overlayColor: WidgetStatePropertyAll(p.primaryBg),
        ),
      ),

      // ── Controles ──────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.bgSunken,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.base,
          vertical: OmniSpacing.md + OmniSpacing.xxs,
        ),
        border: inputBorder(p.borderSubtle),
        enabledBorder: inputBorder(p.borderSubtle),
        disabledBorder: inputBorder(p.borderSubtle),
        focusedBorder: inputBorder(p.primary, OmniSizes.focusRing),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, OmniSizes.focusRing),
        labelStyle: text.bodyMedium!.copyWith(color: p.textMuted),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (s) => text.labelMedium!.copyWith(
            color: s.contains(WidgetState.error)
                ? p.danger
                : s.contains(WidgetState.focused)
                ? p.primaryText
                : p.textMuted,
          ),
        ),
        hintStyle: text.bodyMedium!.copyWith(color: p.textDisabled),
        helperStyle: text.labelSmall,
        errorStyle: text.labelMedium!.copyWith(color: p.danger),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? p.primaryText : p.textMuted,
        ),
        suffixIconColor: p.textMuted,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withAlpha(70),
        selectionHandleColor: p.primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.bgSurface,
        selectedColor: p.primaryBg,
        disabledColor: p.bgRaised,
        side: BorderSide(color: p.borderMuted),
        shape: RoundedRectangleBorder(borderRadius: OmniRadius.fullAll),
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium!.copyWith(color: p.primaryText),
        checkmarkColor: p.primaryText,
        padding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.sm,
          vertical: OmniSpacing.xs,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onPrimary : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.bgRaised,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? OmniPalette.transparent
              : p.borderWeak,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? p.primary
              : OmniPalette.transparent,
        ),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        side: BorderSide(color: p.borderWeak, width: OmniSizes.focusRing),
        shape: RoundedRectangleBorder(borderRadius: OmniRadius.xsAll),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.borderWeak,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.bgRaised,
        circularTrackColor: OmniPalette.transparent,
        refreshBackgroundColor: p.bgSurface,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(p.borderWeak),
        radius: const Radius.circular(OmniRadius.full),
      ),
      iconTheme: IconThemeData(color: p.textSecondary, size: OmniSizes.iconMd),
    );
  }
}
