import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/omni_colors.dart';
import '../tokens/omni_radius.dart';
import '../tokens/omni_spacing.dart';
import 'omni_theme_extensions.dart';

abstract final class OmniTheme {
  static ThemeData dark() {
    const seed = OmniColors.seedColor;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        surface: OmniColors.bgSurface,
      ),
      scaffoldBackgroundColor: OmniColors.bg,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        elevation: 0,
        color: OmniColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: OmniRadius.lgAll,
          side: const BorderSide(color: OmniColors.borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: OmniSpacing.xl,
            vertical: OmniSpacing.base,
          ),
          shape: RoundedRectangleBorder(borderRadius: OmniRadius.mdAll),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: OmniSpacing.xl,
            vertical: OmniSpacing.base,
          ),
          shape: RoundedRectangleBorder(borderRadius: OmniRadius.mdAll),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmniColors.borderSubtle,
        border: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: const BorderSide(color: OmniColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: const BorderSide(color: OmniColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: const BorderSide(color: OmniColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: const BorderSide(color: OmniColors.danger, width: 1.5),
        ),
        hintStyle: const TextStyle(color: OmniColors.textDisabled),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.base,
          vertical: OmniSpacing.md,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: OmniColors.borderSubtle,
        thickness: 1,
        space: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: OmniColors.bgDrawer,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: OmniColors.bgPopup,
        shape: RoundedRectangleBorder(borderRadius: OmniRadius.mdAll),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OmniColors.bgPopup,
        contentTextStyle: const TextStyle(color: OmniColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: OmniRadius.mdAll),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: OmniColors.bgModal,
        shape: RoundedRectangleBorder(borderRadius: OmniRadius.xlAll),
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: OmniColors.bgModal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(OmniRadius.xl)),
        ),
        elevation: 0,
        dragHandleColor: OmniColors.borderWeak,
      ),
      extensions: const [OmniThemeExt.dark],
    );
  }

  static ThemeData light() {
    const seed = OmniColors.seedColor;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.outfitTextTheme(),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: OmniRadius.lgAll,
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: OmniSpacing.xl,
            vertical: OmniSpacing.base,
          ),
          shape: RoundedRectangleBorder(borderRadius: OmniRadius.mdAll),
        ),
      ),
    );
  }
}
