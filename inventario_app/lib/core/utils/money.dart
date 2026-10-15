/// Montos de dinero como enteros en unidades menores (centavos).
///
/// Todas las cantidades monetarias del dominio (`price`, `costPrice`,
/// `unitPrice`, `totalPrice`, `totalAmount`, `totalDebt`, …) son `int` en
/// centavos con una escala fija de [scale] para cualquier moneda (COP también
/// tiene centavos en ISO 4217, aunque no se muestren). Así la aritmética es
/// exacta: sin residuos de coma flotante ni deudas fantasma.
///
/// `double` sólo aparece en el borde: al formatear para mostrar y al migrar
/// datos antiguos ([fromDouble]).
abstract final class Money {
  /// Centavos por unidad mayor.
  static const scale = 100;

  static final _inputPattern = RegExp(r'^\d+([.,]\d{1,2})?$');

  /// Parsea lo que escribe el usuario (`"1500"`, `"1500.5"`, `"9,99"`) a
  /// centavos, sin pasar por `double`. Sin separadores de miles; máximo dos
  /// decimales. Devuelve `null` si el texto no es un monto válido.
  static int? parse(String? input) {
    final text = input?.trim() ?? '';
    if (!_inputPattern.hasMatch(text)) return null;
    final parts = text.replaceAll(',', '.').split('.');
    final whole = int.tryParse(parts[0]);
    if (whole == null) return null;
    final frac = parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0;
    return whole * scale + frac;
  }

  /// Texto para precargar un campo editable: `150050` → `"1500.50"`,
  /// `150000` → `"1500"`.
  static String toInput(int cents) {
    final sign = cents < 0 ? '-' : '';
    final abs = cents.abs();
    final whole = abs ~/ scale;
    final frac = abs % scale;
    return frac == 0
        ? '$sign$whole'
        : '$sign$whole.${frac.toString().padLeft(2, '0')}';
  }

  /// Unidades mayores para formatear o graficar. No usar para aritmética.
  static double toMajor(int cents) => cents / scale;

  /// Convierte un monto legado en unidades mayores (`double`) a centavos,
  /// redondeando la mitad hacia arriba (lejos de cero).
  ///
  /// Redondea sobre la representación decimal más corta del `double`, no
  /// sobre `amount * 100`: `10.005` → 1001 (con `* 100` daría 1000.4999…).
  static int fromDouble(double amount) {
    if (amount.isNaN || amount.isInfinite) {
      throw ArgumentError.value(amount, 'amount', 'monto no finito');
    }
    final text = amount.abs().toString();
    // Notación exponencial (muy grande o residuo diminuto tipo 1e-12).
    if (text.contains('e')) return (amount * scale).round();

    final sign = amount < 0 ? -1 : 1;
    final parts = text.split('.');
    final whole = int.parse(parts[0]);
    final frac = parts.length > 1 ? parts[1] : '';
    final cents = int.parse(frac.padRight(2, '0').substring(0, 2));
    final roundUp = frac.length > 2 && frac.codeUnitAt(2) >= 0x35; // '5'
    return sign * (whole * scale + cents + (roundUp ? 1 : 0));
  }
}
