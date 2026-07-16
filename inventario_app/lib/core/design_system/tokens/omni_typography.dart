import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'omni_colors.dart';

abstract final class OmniTypography {
  // ── Display ────────────────────────────────────────────────────────────────
  static TextStyle displayLg = GoogleFonts.outfit(
    fontSize: 32, fontWeight: FontWeight.w700, color: OmniColors.textPrimary,
  );
  static TextStyle displayMd = GoogleFonts.outfit(
    fontSize: 28, fontWeight: FontWeight.w700, color: OmniColors.textPrimary,
  );

  // ── Heading ────────────────────────────────────────────────────────────────
  static TextStyle headingLg = GoogleFonts.outfit(
    fontSize: 22, fontWeight: FontWeight.w600, color: OmniColors.textPrimary,
  );
  static TextStyle headingMd = GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w600, color: OmniColors.textPrimary,
  );
  static TextStyle headingSm = GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w600, color: OmniColors.textPrimary,
  );

  // ── Body ───────────────────────────────────────────────────────────────────
  static TextStyle bodyLg = GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w400, color: OmniColors.textPrimary,
  );
  static TextStyle bodyMd = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w400, color: OmniColors.textPrimary,
  );
  static TextStyle bodySm = GoogleFonts.outfit(
    fontSize: 13, fontWeight: FontWeight.w400, color: OmniColors.textSecondary,
  );

  // ── Label / Caption ────────────────────────────────────────────────────────
  static TextStyle label = GoogleFonts.outfit(
    fontSize: 12, fontWeight: FontWeight.w500, color: OmniColors.textSecondary,
  );
  static TextStyle caption = GoogleFonts.outfit(
    fontSize: 11, fontWeight: FontWeight.w500, color: OmniColors.textMuted,
  );

  // ── Numeric / Prices ───────────────────────────────────────────────────────
  static TextStyle priceLg = GoogleFonts.outfit(
    fontSize: 22, fontWeight: FontWeight.w700, color: OmniColors.textPrimary,
  );
  static TextStyle priceHero = GoogleFonts.outfit(
    fontSize: 52, fontWeight: FontWeight.w800, color: OmniColors.textPrimary,
  );
}
