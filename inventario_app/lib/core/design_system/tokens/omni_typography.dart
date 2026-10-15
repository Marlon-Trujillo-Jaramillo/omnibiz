
import 'package:flutter/material.dart';
import 'omni_colors.dart';

/// Escala tipográfica de OmniBiz. Outfit va empaquetada en
/// `assets/fonts/outfit/` (la app funciona offline: nada se descarga).
///
/// Estos estilos base no llevan color: en pantallas usa `context.text.*`,
/// que aplica el color del tema activo (ver [OmniText]).
abstract final class OmniTypography {
  static const String fontFamily = 'Outfit';

  /// Cifras de ancho fijo: montos y cantidades no "bailan" al cambiar.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const TextStyle _base = TextStyle(
    fontFamily: fontFamily,
    leadingDistribution: TextLeadingDistribution.even,
  );

  // ── Display ────────────────────────────────────────────────────────────────
  static final TextStyle displayLg = _base.copyWith(
    fontSize: 34,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
  );
  static final TextStyle displayMd = _base.copyWith(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  // ── Heading ────────────────────────────────────────────────────────────────
  static final TextStyle headingLg = _base.copyWith(
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  static final TextStyle headingMd = _base.copyWith(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static final TextStyle headingSm = _base.copyWith(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  // ── Body ───────────────────────────────────────────────────────────────────
  static final TextStyle bodyLg = _base.copyWith(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle bodyMd = _base.copyWith(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle bodySm = _base.copyWith(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  // ── Label / Caption ────────────────────────────────────────────────────────
  static final TextStyle label = _base.copyWith(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static final TextStyle caption = _base.copyWith(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  /// Rótulo de sección en mayúsculas.
  static final TextStyle overline = _base.copyWith(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );

  /// Etiquetas diminutas (contador de badge).
  static final TextStyle micro = _base.copyWith(
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  // ── Numérico (siempre tabular) ─────────────────────────────────────────────
  static final TextStyle moneySm = _base.copyWith(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    fontFeatures: tabular,
  );
  static final TextStyle moneyMd = _base.copyWith(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w700,
    fontFeatures: tabular,
  );
  static final TextStyle priceLg = _base.copyWith(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    fontFeatures: tabular,
  );
  static final TextStyle priceXl = _base.copyWith(
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    fontFeatures: tabular,
  );
  static final TextStyle priceHero = _base.copyWith(
    fontSize: 48,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.4,
    fontFeatures: tabular,
  );

  /// Glifo grande de una tecla numérica (PIN pad).
  static final TextStyle keypad = _base.copyWith(
    fontSize: 28,
    height: 1,
    fontWeight: FontWeight.w500,
    fontFeatures: tabular,
  );

  /// `TextTheme` de Material construido con esta escala y [p].
  static TextTheme textTheme(OmniPalette p) => TextTheme(
    displayLarge: displayLg.copyWith(color: p.textPrimary),
    displayMedium: displayMd.copyWith(color: p.textPrimary),
    displaySmall: headingLg.copyWith(color: p.textPrimary),
    headlineLarge: displayMd.copyWith(color: p.textPrimary),
    headlineMedium: headingLg.copyWith(color: p.textPrimary),
    headlineSmall: headingMd.copyWith(color: p.textPrimary),
    titleLarge: headingMd.copyWith(color: p.textPrimary),
    titleMedium: headingSm.copyWith(color: p.textPrimary),
    titleSmall: bodyMd.copyWith(
      color: p.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: bodyLg.copyWith(color: p.textPrimary),
    bodyMedium: bodyMd.copyWith(color: p.textPrimary),
    bodySmall: bodySm.copyWith(color: p.textSecondary),
    labelLarge: bodyMd.copyWith(
      color: p.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: label.copyWith(color: p.textSecondary),
    labelSmall: caption.copyWith(color: p.textMuted),
  );
}

/// Estilos de [OmniTypography] con el color por defecto del tema activo.
/// Se obtiene con `context.text`; ajusta con `.copyWith(color: …)`.
class OmniText {
  const OmniText(this._p);
  final OmniPalette _p;

  TextStyle get displayLg =>
      OmniTypography.displayLg.copyWith(color: _p.textPrimary);
  TextStyle get displayMd =>
      OmniTypography.displayMd.copyWith(color: _p.textPrimary);
  TextStyle get headingLg =>
      OmniTypography.headingLg.copyWith(color: _p.textPrimary);
  TextStyle get headingMd =>
      OmniTypography.headingMd.copyWith(color: _p.textPrimary);
  TextStyle get headingSm =>
      OmniTypography.headingSm.copyWith(color: _p.textPrimary);
  TextStyle get bodyLg => OmniTypography.bodyLg.copyWith(color: _p.textPrimary);
  TextStyle get bodyMd => OmniTypography.bodyMd.copyWith(color: _p.textPrimary);
  TextStyle get bodySm =>
      OmniTypography.bodySm.copyWith(color: _p.textSecondary);
  TextStyle get label => OmniTypography.label.copyWith(color: _p.textSecondary);
  TextStyle get caption => OmniTypography.caption.copyWith(color: _p.textMuted);
  TextStyle get overline =>
      OmniTypography.overline.copyWith(color: _p.textMuted);
  TextStyle get micro => OmniTypography.micro.copyWith(color: _p.textPrimary);
  TextStyle get moneySm =>
      OmniTypography.moneySm.copyWith(color: _p.textPrimary);
  TextStyle get moneyMd =>
      OmniTypography.moneyMd.copyWith(color: _p.textPrimary);
  TextStyle get priceLg =>
      OmniTypography.priceLg.copyWith(color: _p.textPrimary);
  TextStyle get priceXl =>
      OmniTypography.priceXl.copyWith(color: _p.textPrimary);
  TextStyle get priceHero =>
      OmniTypography.priceHero.copyWith(color: _p.textPrimary);
  TextStyle get keypad => OmniTypography.keypad.copyWith(color: _p.textPrimary);
}

extension OmniTextStyleX on TextStyle {
  /// Cifras tabulares (montos, cantidades, contadores).
  TextStyle get tabular => copyWith(fontFeatures: OmniTypography.tabular);
}
