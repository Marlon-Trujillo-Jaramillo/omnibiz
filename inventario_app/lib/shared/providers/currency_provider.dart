import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inventario_app/core/utils/app_currency.dart';
import 'package:inventario_app/core/utils/currency_formatter.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final currencyProvider = NotifierProvider<CurrencyNotifier, AppCurrency>(
  CurrencyNotifier.new,
);

class CurrencyNotifier extends Notifier<AppCurrency> {
  static const _key = 'app_currency';
  static const _storage = FlutterSecureStorage();

  @override
  AppCurrency build() {
    _load();
    return AppCurrency.cop;
  }

  Future<void> _load() async {
    final value = await _storage.read(key: _key);
    if (value != null) state = _parse(value);
  }

  /// Moneda guardada, leída fuera de Riverpod (p. ej. en `main` antes de
  /// abrir la BD, para etiquetar ventas antiguas en la migración).
  static Future<AppCurrency> readStored() async {
    try {
      return _parse(await _storage.read(key: _key));
    } catch (_) {
      return AppCurrency.cop;
    }
  }

  static AppCurrency _parse(String? value) => AppCurrency.values.firstWhere(
    (c) => c.name == value,
    orElse: () => AppCurrency.cop,
  );

  Future<void> setCurrency(AppCurrency currency) async {
    state = currency;
    await _storage.write(key: _key, value: currency.name);
  }
}

// ── WidgetRef extension ────────────────────────────────────────────────────────

extension MoneyFormat on WidgetRef {
  /// [cents] en centavos (ver `Money`), con la moneda configurada.
  String formatMoney(int cents) =>
      CurrencyFormatter.format(cents, watch(currencyProvider));

  String formatMoneyCompact(int cents) =>
      CurrencyFormatter.compact(cents, watch(currencyProvider));

  /// Monto de una venta: siempre con la moneda en que se registró.
  String formatSaleMoney(int cents, String currencyCode) =>
      CurrencyFormatter.format(cents, AppCurrency.fromCode(currencyCode));
}
