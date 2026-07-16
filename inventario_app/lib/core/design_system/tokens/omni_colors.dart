import 'package:flutter/material.dart';

abstract final class OmniColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color bg       = Color(0xFF0A0A0A);
  static const Color bgSurface = Color(0xFF1E1E1E);
  static const Color bgModal  = Color(0xFF1A1A1A);
  static const Color bgDrawer = Color(0xFF141414);
  static const Color bgPopup  = Color(0xFF2A2A2A);
  static const Color bgPanel  = Color(0xFF161616);

  // ── Borders ────────────────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0x0DFFFFFF); // white 5%
  static const Color borderMuted  = Color(0x14FFFFFF); // white 8%
  static const Color borderWeak   = Color(0x33FFFFFF); // white 20%

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0x8AFFFFFF); // white54
  static const Color textMuted     = Color(0x61FFFFFF); // white38
  static const Color textDisabled  = Color(0x3DFFFFFF); // white24

  // ── Brand / Semantic ───────────────────────────────────────────────────────
  static const Color primary = Colors.indigoAccent;
  static const Color success = Colors.greenAccent;
  static const Color warning = Colors.amberAccent;
  static const Color danger  = Colors.redAccent;
  static const Color purple  = Colors.purpleAccent;
  static const Color orange  = Colors.orangeAccent;
  static const Color blue    = Colors.blueAccent;

  // ── Tinted backgrounds (semantic) ─────────────────────────────────────────
  static const Color primaryBg = Color(0x1A7986CB); // indigoAccent ~10%
  static const Color successBg = Color(0x1A69F0AE); // greenAccent ~10%
  static const Color warningBg = Color(0x1AFFD740); // amberAccent ~10%
  static const Color dangerBg  = Color(0x1AFF5252); // redAccent ~10%

  // ── Seed para Material3 ColorScheme ───────────────────────────────────────
  static const Color seedColor = Colors.indigo;
}
