import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';

CustomerEntity _customer({
  int id = 1,
  String name = 'Ana García',
  int totalDebt = 0,
}) => CustomerEntity(
  id: id,
  name: name,
  totalDebt: totalDebt,
  createdAt: DateTime(2024),
  storeId: 0,
);

void main() {
  group('CustomerEntity.hasDebt', () {
    test('false cuando deuda es 0', () {
      expect(_customer(totalDebt: 0).hasDebt, false);
    });

    test('true cuando deuda > 0', () {
      expect(_customer(totalDebt: 15000).hasDebt, true);
    });
  });

  group('CustomerEntity.initials', () {
    test('nombre compuesto toma primera de cada apellido', () {
      expect(_customer(name: 'Ana García').initials, 'AG');
    });

    test('nombre simple toma primera letra', () {
      expect(_customer(name: 'Carlos').initials, 'C');
    });

    test('nombre vacío retorna ?', () {
      expect(_customer(name: '').initials, '?');
    });

    test('mayúsculas', () {
      expect(_customer(name: 'juan perez').initials, 'JP');
    });
  });

  group('CustomerEntity.copyWith', () {
    test('modifica totalDebt', () {
      final base = _customer(totalDebt: 1000);
      final copy = base.copyWith(totalDebt: 2000);
      expect(copy.totalDebt, 2000);
      expect(copy.name, base.name);
    });

    test('modifica phone preservando resto', () {
      final base = _customer(name: 'Pedro');
      final copy = base.copyWith(phone: '300123');
      expect(copy.phone, '300123');
      expect(copy.name, 'Pedro');
    });
  });
}
