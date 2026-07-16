enum AppCurrency { cop, usd }

extension AppCurrencyExt on AppCurrency {
  String get code => switch (this) {
    AppCurrency.cop => 'COP',
    AppCurrency.usd => 'USD',
  };

  String get label => switch (this) {
    AppCurrency.cop => 'Peso Colombiano (COP)',
    AppCurrency.usd => 'Dólar Estadounidense (USD)',
  };

  String get flag => switch (this) {
    AppCurrency.cop => '🇨🇴',
    AppCurrency.usd => '🇺🇸',
  };
}
