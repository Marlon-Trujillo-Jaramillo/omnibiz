import 'package:intl/intl.dart';
import 'app_currency.dart';
import 'money.dart';

/// Formatea montos en centavos (ver [Money]) según la moneda.
abstract final class CurrencyFormatter {
  // Patrón explícito con el símbolo ADELANTE: los datos de intl para es_CO
  // lo ponen al final ("4.500 $"), pero en Colombia se escribe "$4.500".
  static final _fmt = {
    AppCurrency.cop: NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
      customPattern: '\u00A4#,##0',
    ),
    AppCurrency.usd: NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    ),
  };

  static final _compact = {
    AppCurrency.cop: NumberFormat.compact(locale: 'es_CO'),
    AppCurrency.usd: NumberFormat.compact(locale: 'en_US'),
  };

  static String format(int cents, AppCurrency currency) =>
      _fmt[currency]!.format(Money.toMajor(cents));

  /// `$613 mil` (COP) / `$1.2K` (USD).
  static String compact(int cents, AppCurrency currency) =>
      '\$${_compact[currency]!.format(Money.toMajor(cents))}';
}
