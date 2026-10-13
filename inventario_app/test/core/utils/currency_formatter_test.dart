import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/core/utils/app_currency.dart';
import 'package:inventario_app/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.format (centavos)', () {
    test('COP: símbolo adelante, como se escribe en Colombia', () {
      expect(CurrencyFormatter.format(450000, AppCurrency.cop), '\$4.500');
      expect(CurrencyFormatter.compact(61320000, AppCurrency.cop), '\$613\u00A0mil');
    });

    test('COP: contiene los miles y el símbolo', () {
      final result = CurrencyFormatter.format(100000, AppCurrency.cop);
      expect(result, contains('1.000'));
      expect(result, contains('\$'));
    });

    test('COP: cero contiene símbolo', () {
      final result = CurrencyFormatter.format(0, AppCurrency.cop);
      expect(result, contains('0'));
      expect(result, contains('\$'));
    });

    test('COP: número grande incluye separadores', () {
      final result = CurrencyFormatter.format(150000000, AppCurrency.cop);
      expect(result, contains('1.500.000'));
    });

    test('COP: sin decimales de centavos', () {
      final result = CurrencyFormatter.format(500099, AppCurrency.cop);
      expect(result, isNot(contains(',99')));
      expect(result, isNot(contains('.99')));
    });

    test('USD: dos decimales presentes', () {
      final result = CurrencyFormatter.format(999, AppCurrency.usd);
      expect(result, contains('9.99'));
      expect(result, contains('\$'));
    });

    test('USD: sin centavos muestra .00', () {
      final result = CurrencyFormatter.format(10000, AppCurrency.usd);
      expect(result, contains('100.00'));
    });
  });

  group('CurrencyFormatter.compact', () {
    test('COP: millones abreviados contiene el valor', () {
      final result = CurrencyFormatter.compact(250000000, AppCurrency.cop);
      expect(result, isNotEmpty);
      // el número compacto es más corto que el valor completo formateado
      expect(result.length,
          lessThan(CurrencyFormatter.format(250000000, AppCurrency.cop).length));
    });

    test('COP: miles abreviados retorna cadena no vacía con símbolo', () {
      final result = CurrencyFormatter.compact(1500000, AppCurrency.cop);
      expect(result, isNotEmpty);
      expect(result, contains('\$'));
    });

    test('USD: millones compacto contiene símbolo', () {
      final result = CurrencyFormatter.compact(150000000, AppCurrency.usd);
      expect(result, contains('\$'));
    });
  });

  group('AppCurrency metadata', () {
    test('COP code es COP', () => expect(AppCurrency.cop.code, 'COP'));
    test('USD code es USD', () => expect(AppCurrency.usd.code, 'USD'));
    test('COP label contiene Peso', () {
      expect(AppCurrency.cop.label, contains('Peso'));
    });
    test('USD label contiene Dólar', () {
      expect(AppCurrency.usd.label, contains('Dólar'));
    });
    test('fromCode resuelve el código y cae en COP si es desconocido', () {
      expect(AppCurrency.fromCode('USD'), AppCurrency.usd);
      expect(AppCurrency.fromCode('COP'), AppCurrency.cop);
      expect(AppCurrency.fromCode(null), AppCurrency.cop);
      expect(AppCurrency.fromCode('EUR'), AppCurrency.cop);
    });
  });
}
