import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/core/utils/money.dart';

void main() {
  group('Money.parse', () {
    test('enteros y decimales a centavos', () {
      expect(Money.parse('1500'), 150000);
      expect(Money.parse('1500.5'), 150050);
      expect(Money.parse('1500.05'), 150005);
      expect(Money.parse('9,99'), 999);
      expect(Money.parse(' 0 '), 0);
      expect(Money.parse('0.1'), 10);
    });

    test('rechaza entradas inválidas', () {
      for (final bad in [null, '', 'abc', '-5', '1.234', '1.000,50', '1e3', '.5', '5.']) {
        expect(Money.parse(bad), isNull, reason: '"$bad"');
      }
    });

    test('0.1 + 0.2 es exacto en centavos', () {
      expect(Money.parse('0.1')! + Money.parse('0.2')!, Money.parse('0.3'));
    });
  });

  group('Money.toInput', () {
    test('ida y vuelta con parse', () {
      for (final cents in [0, 5, 10, 999, 150000, 150050, 123456789]) {
        expect(Money.parse(Money.toInput(cents)), cents);
      }
      expect(Money.toInput(150000), '1500');
      expect(Money.toInput(150005), '1500.05');
    });
  });

  group('Money.fromDouble (migración de datos legados)', () {
    test('valores exactos', () {
      expect(Money.fromDouble(5000.0), 500000);
      expect(Money.fromDouble(9.99), 999);
      expect(Money.fromDouble(0), 0);
    });

    test('redondea la mitad hacia arriba', () {
      expect(Money.fromDouble(10.005), 1001); // 10.005 * 100 = 1000.4999…
      expect(Money.fromDouble(1.115), 112);
      expect(Money.fromDouble(1.114), 111);
      expect(Money.fromDouble(2.675), 268);
    });

    test('elimina residuos de coma flotante', () {
      expect(Money.fromDouble(0.1 + 0.2), 30);
      expect(Money.fromDouble(10.01 - 10), 1);
      expect(Money.fromDouble(1e-12), 0); // deuda "fantasma"
      expect(Money.fromDouble(15000.000000000002), 1500000);
    });

    test('negativos simétricos', () {
      expect(Money.fromDouble(-10.005), -1001);
      expect(Money.fromDouble(-1.5), -150);
    });

    test('no acepta NaN/infinito', () {
      expect(() => Money.fromDouble(double.nan), throwsArgumentError);
      expect(() => Money.fromDouble(double.infinity), throwsArgumentError);
    });
  });
}
