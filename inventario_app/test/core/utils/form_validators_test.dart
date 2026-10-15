import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/core/utils/form_validators.dart';

void main() {
  group('FormValidators.required', () {
    test('null retorna error', () {
      expect(FormValidators.required(null), isNotNull);
    });

    test('vacío retorna error', () {
      expect(FormValidators.required(''), isNotNull);
    });

    test('solo espacios retorna error', () {
      expect(FormValidators.required('   '), isNotNull);
    });

    test('valor válido retorna null', () {
      expect(FormValidators.required('hola'), isNull);
    });
  });

  group('FormValidators.money', () {
    test('cero retorna error', () {
      expect(FormValidators.money('0'), isNotNull);
    });

    test('negativo retorna error', () {
      expect(FormValidators.money('-5'), isNotNull);
    });

    test('texto retorna error', () {
      expect(FormValidators.money('abc'), isNotNull);
    });

    test('positivo válido retorna null', () {
      expect(FormValidators.money('10.5'), isNull);
    });

    test('vacío retorna error', () {
      expect(FormValidators.money(''), isNotNull);
    });

    test('más de dos decimales retorna error', () {
      expect(FormValidators.money('10.555'), isNotNull);
    });

    test('allowZero acepta cero', () {
      expect(FormValidators.money('0', 'Costo', true), isNull);
    });
  });

  group('FormValidators.nonNegativeInt', () {
    test('negativo retorna error', () {
      expect(FormValidators.nonNegativeInt('-1'), isNotNull);
    });

    test('decimal retorna error', () {
      expect(FormValidators.nonNegativeInt('3.5'), isNotNull);
    });

    test('cero es válido', () {
      expect(FormValidators.nonNegativeInt('0'), isNull);
    });

    test('entero positivo válido', () {
      expect(FormValidators.nonNegativeInt('10'), isNull);
    });
  });

  group('FormValidators.phone', () {
    test('null es válido (opcional)', () {
      expect(FormValidators.phone(null), isNull);
    });

    test('vacío es válido (opcional)', () {
      expect(FormValidators.phone(''), isNull);
    });

    test('menos de 7 dígitos retorna error', () {
      expect(FormValidators.phone('123'), isNotNull);
    });

    test('número válido retorna null', () {
      expect(FormValidators.phone('3001234567'), isNull);
    });
  });

  group('FormValidators.email', () {
    test('null es válido (opcional)', () {
      expect(FormValidators.email(null), isNull);
    });

    test('sin arroba retorna error', () {
      expect(FormValidators.email('usuario.dominio.com'), isNotNull);
    });

    test('correo válido retorna null', () {
      expect(FormValidators.email('test@example.com'), isNull);
    });
  });

  group('FormValidators.pin', () {
    test('null retorna error', () {
      expect(FormValidators.pin(null), isNotNull);
    });

    test('menos de 4 dígitos retorna error', () {
      expect(FormValidators.pin('123'), isNotNull);
    });

    test('más de 4 dígitos retorna error', () {
      expect(FormValidators.pin('12345'), isNotNull);
    });

    test('letras retorna error', () {
      expect(FormValidators.pin('ab12'), isNotNull);
    });

    test('4 dígitos válido', () {
      expect(FormValidators.pin('1234'), isNull);
    });
  });

  group('FormValidators.combine', () {
    test('primer error detiene la cadena', () {
      final validator = FormValidators.combine([
        FormValidators.required,
        (v) => v!.length > 3 ? null : 'Muy corto',
      ]);
      expect(validator(''), isNotNull);
    });

    test('todos pasan retorna null', () {
      final validator = FormValidators.combine([
        FormValidators.required,
        (v) => v!.length > 2 ? null : 'Muy corto',
      ]);
      expect(validator('hola'), isNull);
    });
  });
}
