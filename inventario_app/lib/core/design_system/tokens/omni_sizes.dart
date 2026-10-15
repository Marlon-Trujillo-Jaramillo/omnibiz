import 'package:flutter/animation.dart';

/// Tamaños fijos de íconos y controles (evita números mágicos en pantallas).
abstract final class OmniSizes {
  // ── Íconos ────────────────────────────────────────────────────────────────
  static const double iconXs = 14;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double iconHero = 40;

  // ── Controles (alto mínimo táctil) ──────────────────────────────────────────
  static const double controlSm = 36;
  static const double controlMd = 48;
  static const double controlLg = 56;
  static const double controlXl = 64;

  // ── Avatares / contenedores de ícono ───────────────────────────────────────
  static const double avatarSm = 36;
  static const double avatarMd = 44;
  static const double avatarLg = 56;
  static const double avatarXl = 72;

  // ── Trazos ─────────────────────────────────────────────────────────────────
  static const double hairline = 1;
  static const double focusRing = 1.5;
  static const double stroke = 2;

  /// Punto del PIN.
  static const double pinDot = 14;
  /// Ancho máximo de un panel lateral (carrito en tablet).
  static const double sidePanel = 400;
}

/// Duraciones y curvas de las animaciones.
abstract final class OmniMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration shimmer = Duration(milliseconds: 1400);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
}
