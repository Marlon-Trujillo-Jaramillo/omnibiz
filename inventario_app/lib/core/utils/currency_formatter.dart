import 'package:intl/intl.dart';
import 'app_currency.dart';

abstract final class CurrencyFormatter {
  static final _fmt = {
    AppCurrency.cop: NumberFormat.currency(
      locale: 'es_CO', symbol: '\$', decimalDigits: 0),
    AppCurrency.usd: NumberFormat.currency(
      locale: 'en_US', symbol: '\$', decimalDigits: 2),
  };

  static final _compact = {
    AppCurrency.cop: NumberFormat.compactCurrency(
      locale: 'es_CO', symbol: '\$', decimalDigits: 0),
    AppCurrency.usd: NumberFormat.compactCurrency(
      locale: 'en_US', symbol: '\$', decimalDigits: 1),
  };

  static String format(double amount, AppCurrency currency) =>
      _fmt[currency]!.format(amount);

  static String compact(double amount, AppCurrency currency) =>
      _compact[currency]!.format(amount);
}
