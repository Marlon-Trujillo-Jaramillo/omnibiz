import 'package:flutter/material.dart';
import '../tokens/omni_colors.dart';
import '../tokens/omni_typography.dart';

/// Acceso a los tokens del tema activo.
extension OmniThemeContext on BuildContext {
  /// Paleta del tema activo (clara u oscura). Sin `OmniTheme` (p. ej. en un
  /// test con `MaterialApp` pelado) cae a la paleta oscura.
  OmniPalette get colors =>
      Theme.of(this).extension<OmniPalette>() ?? OmniPalette.dark;

  /// Escala tipográfica con los colores del tema activo.
  OmniText get text => OmniText(colors);
}
