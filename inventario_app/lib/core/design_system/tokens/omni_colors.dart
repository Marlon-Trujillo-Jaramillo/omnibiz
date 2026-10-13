import 'package:flutter/material.dart';

/// Paleta de OmniBiz, única fuente de colores de la app.
///
/// Es un [ThemeExtension] con una instancia clara y otra oscura con la misma
/// identidad (violeta-índigo sobre grafito azulado / blanco frío). Se lee con
/// `context.colors` (ver `omni_theme_extensions.dart`), así cada pantalla
/// sigue al tema activo sin referenciar colores estáticos.
///
/// Contraste (WCAG 2.1) verificado en ambas variantes:
/// - texto primario/secundario ≥ 7:1 sobre superficies, `textMuted` ≥ 4.5:1;
/// - semánticos (`success`, `warning`, `danger`, `info`, `primaryText`) ≥ 4.5:1
///   sobre su tinte `*Bg` y sobre `bgSurface`;
/// - blanco sobre `primary` 4.9:1 y sobre `dangerFill` 4.8:1.
@immutable
class OmniPalette extends ThemeExtension<OmniPalette> {
  const OmniPalette({
    required this.brightness,
    required this.bg,
    required this.bgSurface,
    required this.bgRaised,
    required this.bgPanel,
    required this.bgModal,
    required this.bgPopup,
    required this.bgSunken,
    required this.borderSubtle,
    required this.borderMuted,
    required this.borderWeak,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.primary,
    required this.primaryText,
    required this.primaryBg,
    required this.onPrimary,
    required this.brandEnd,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
    required this.dangerFill,
    required this.info,
    required this.infoBg,
    required this.purple,
    required this.orange,
    required this.teal,
    required this.snackBg,
    required this.onSnack,
    required this.scrim,
    required this.shadow,
  });

  final Brightness brightness;

  // ── Superficies (de atrás hacia adelante) ──────────────────────────────────
  /// Lienzo de cada pantalla.
  final Color bg;

  /// Tarjetas y filas de lista.
  final Color bgSurface;

  /// Elementos sobre una tarjeta (stepper, teclas del PIN, chips neutros).
  final Color bgRaised;

  /// Paneles laterales (carrito en tablet, drawer).
  final Color bgPanel;

  /// Diálogos y bottom sheets.
  final Color bgModal;

  /// Menús emergentes.
  final Color bgPopup;

  /// Relleno de campos de texto.
  final Color bgSunken;

  // ── Bordes ─────────────────────────────────────────────────────────────────
  final Color borderSubtle;
  final Color borderMuted;

  /// Borde fuerte: controles, asas de arrastre.
  final Color borderWeak;

  // ── Texto ──────────────────────────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;

  // ── Marca ──────────────────────────────────────────────────────────────────
  /// Relleno de marca (botones, selección, íconos).
  final Color primary;

  /// Marca como texto sobre superficies (AA en ambos temas).
  final Color primaryText;

  /// Tinte de marca para fondos de selección.
  final Color primaryBg;
  final Color onPrimary;

  /// Pareja del degradado de marca (violeta). Usar con moderación.
  final Color brandEnd;

  // ── Semánticos ─────────────────────────────────────────────────────────────
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;

  /// Relleno de botones destructivos (texto [onPrimary] encima).
  final Color dangerFill;
  final Color info;
  final Color infoBg;

  // ── Acentos (categorías, accesos rápidos, gráficos) ─────────────────────────
  final Color purple;
  final Color orange;
  final Color teal;

  // ── Overlays ───────────────────────────────────────────────────────────────
  /// Fondo de snackbars: siempre oscuro, para que los tonos de
  /// [OmniPalette.dark] se lean igual en ambos temas.
  final Color snackBg;
  final Color onSnack;
  final Color scrim;
  final Color shadow;

  /// Fondo de vistas de cámara/medios.
  Color get mediaBg => _black;

  bool get isDark => brightness == Brightness.dark;

  /// Degradado de marca: CTA principal ("Cobrar") y KPI héroe.
  LinearGradient get brandGradient => LinearGradient(
    colors: [primary, brandEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Sombra suave para tarjetas en tema claro; en oscuro la jerarquía la dan
  /// las superficies y los bordes.
  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [BoxShadow(color: shadow, blurRadius: 12, offset: const Offset(0, 2))];

  /// Sombra para elementos flotantes (CTA, hero, sheets).
  List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: isDark ? _black.withAlpha(110) : shadow.withAlpha(40),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Halo de color bajo un CTA de marca.
  List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withAlpha(isDark ? 70 : 60),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static const Color transparent = Color(0x00000000);
  static const Color _black = Color(0xFF000000);
  static const Color _white = Color(0xFFFFFFFF);

  // ── Instancias ─────────────────────────────────────────────────────────────

  /// Grafito azulado en capas (no negro puro).
  static const OmniPalette dark = OmniPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0B0E14),
    bgSurface: Color(0xFF121621),
    bgRaised: Color(0xFF191E2B),
    bgPanel: Color(0xFF0F121A),
    bgModal: Color(0xFF141824),
    bgPopup: Color(0xFF1E2433),
    bgSunken: Color(0xFF0E1119),
    borderSubtle: Color(0xFF1E2433),
    borderMuted: Color(0xFF232A3A),
    borderWeak: Color(0xFF343D52),
    textPrimary: Color(0xFFEEF1F7),
    textSecondary: Color(0xFFA3ACBF),
    textMuted: Color(0xFF7C879C),
    textDisabled: Color(0xFF4F5A6E),
    primary: Color(0xFF5B5BF7),
    primaryText: Color(0xFF8B8CFF),
    primaryBg: Color(0x295B5BF7), // 16 %
    onPrimary: _white,
    brandEnd: Color(0xFF8B5CF6),
    success: Color(0xFF34D399),
    successBg: Color(0x2434D399), // 14 %
    warning: Color(0xFFFBBF24),
    warningBg: Color(0x24FBBF24),
    danger: Color(0xFFF87171),
    dangerBg: Color(0x24F87171),
    dangerFill: Color(0xFFDC2626),
    info: Color(0xFF60A5FA),
    infoBg: Color(0x2460A5FA),
    purple: Color(0xFFA78BFA),
    orange: Color(0xFFFB923C),
    teal: Color(0xFF2DD4BF),
    snackBg: Color(0xFF1E2433),
    onSnack: Color(0xFFEEF1F7),
    scrim: Color(0x99000000),
    shadow: Color(0x66000000),
  );

  /// Blanco frío con tarjetas blancas y bordes suaves.
  static const OmniPalette light = OmniPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF5F6FA),
    bgSurface: Color(0xFFFFFFFF),
    bgRaised: Color(0xFFF1F3F8),
    bgPanel: Color(0xFFFFFFFF),
    bgModal: Color(0xFFFFFFFF),
    bgPopup: Color(0xFFFFFFFF),
    bgSunken: Color(0xFFF1F3F8),
    borderSubtle: Color(0xFFE4E7EF),
    borderMuted: Color(0xFFDADEE8),
    borderWeak: Color(0xFFC7CDD9),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF5F6675),
    textDisabled: Color(0xFF9CA3AF),
    primary: Color(0xFF5B5BF7),
    primaryText: Color(0xFF4F4FE6),
    primaryBg: Color(0x1A5B5BF7), // 10 %
    onPrimary: _white,
    brandEnd: Color(0xFF8B5CF6),
    success: Color(0xFF047857),
    successBg: Color(0x1F10B981), // 12 %
    warning: Color(0xFFA14A06),
    warningBg: Color(0x24F59E0B), // 14 %
    danger: Color(0xFFB91C1C),
    dangerBg: Color(0x1AEF4444), // 10 %
    dangerFill: Color(0xFFDC2626),
    info: Color(0xFF1D4ED8),
    infoBg: Color(0x1A3B82F6),
    purple: Color(0xFF7C3AED),
    orange: Color(0xFFC2410C),
    teal: Color(0xFF0F766E),
    snackBg: Color(0xFF111827),
    onSnack: Color(0xFFF9FAFB),
    scrim: Color(0x66111827),
    shadow: Color(0x14111827),
  );

  @override
  OmniPalette copyWith({Brightness? brightness}) =>
      (brightness ?? this.brightness) == Brightness.dark ? dark : light;

  @override
  OmniPalette lerp(OmniPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return OmniPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: l(bg, other.bg),
      bgSurface: l(bgSurface, other.bgSurface),
      bgRaised: l(bgRaised, other.bgRaised),
      bgPanel: l(bgPanel, other.bgPanel),
      bgModal: l(bgModal, other.bgModal),
      bgPopup: l(bgPopup, other.bgPopup),
      bgSunken: l(bgSunken, other.bgSunken),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      borderMuted: l(borderMuted, other.borderMuted),
      borderWeak: l(borderWeak, other.borderWeak),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textDisabled: l(textDisabled, other.textDisabled),
      primary: l(primary, other.primary),
      primaryText: l(primaryText, other.primaryText),
      primaryBg: l(primaryBg, other.primaryBg),
      onPrimary: l(onPrimary, other.onPrimary),
      brandEnd: l(brandEnd, other.brandEnd),
      success: l(success, other.success),
      successBg: l(successBg, other.successBg),
      warning: l(warning, other.warning),
      warningBg: l(warningBg, other.warningBg),
      danger: l(danger, other.danger),
      dangerBg: l(dangerBg, other.dangerBg),
      dangerFill: l(dangerFill, other.dangerFill),
      info: l(info, other.info),
      infoBg: l(infoBg, other.infoBg),
      purple: l(purple, other.purple),
      orange: l(orange, other.orange),
      teal: l(teal, other.teal),
      snackBg: l(snackBg, other.snackBg),
      onSnack: l(onSnack, other.onSnack),
      scrim: l(scrim, other.scrim),
      shadow: l(shadow, other.shadow),
    );
  }
}

/// Tono semántico de un componente (badge, snackbar, avatar, banner).
enum OmniTone { neutral, brand, success, warning, danger, info }

extension OmniToneColors on OmniPalette {
  /// Color de primer plano (texto/ícono) del tono, AA sobre [toneBg].
  Color toneFg(OmniTone tone) => switch (tone) {
    OmniTone.neutral => textSecondary,
    OmniTone.brand => primaryText,
    OmniTone.success => success,
    OmniTone.warning => warning,
    OmniTone.danger => danger,
    OmniTone.info => info,
  };

  /// Tinte de fondo del tono.
  Color toneBg(OmniTone tone) => switch (tone) {
    OmniTone.neutral => bgRaised,
    OmniTone.brand => primaryBg,
    OmniTone.success => successBg,
    OmniTone.warning => warningBg,
    OmniTone.danger => dangerBg,
    OmniTone.info => infoBg,
  };
}
