import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inventario_app/core/utils/app_currency.dart';
import 'package:inventario_app/core/utils/currency_formatter.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final currencyProvider =
    NotifierProvider<CurrencyNotifier, AppCurrency>(CurrencyNotifier.new);

class CurrencyNotifier extends Notifier<AppCurrency> {
  static const _key     = 'app_currency';
  static const _storage = FlutterSecureStorage();

  @override
  AppCurrency build() {
    _load();
    return AppCurrency.cop;
  }

  Future<void> _load() async {
    final value = await _storage.read(key: _key);
    if (value != null) {
      state = AppCurrency.values.firstWhere(
        (c) => c.name == value,
        orElse: () => AppCurrency.cop,
      );
    }
  }

  Future<void> setCurrency(AppCurrency currency) async {
    state = currency;
    await _storage.write(key: _key, value: currency.name);
  }
}

// ── WidgetRef extension ────────────────────────────────────────────────────────

extension MoneyFormat on WidgetRef {
  String formatMoney(double amount) =>
      CurrencyFormatter.format(amount, watch(currencyProvider));

  String formatMoneyCompact(double amount) =>
      CurrencyFormatter.compact(amount, watch(currencyProvider));
}
