enum AppCurrency {
  cop,
  usd;

  /// Moneda a partir de su código ISO guardado en una venta. Códigos
  /// desconocidos caen en COP (la moneda por defecto de la app).
  static AppCurrency fromCode(String? code) => AppCurrency.values.firstWhere(
    (c) => c.code == code,
    orElse: () => AppCurrency.cop,
  );
}

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
