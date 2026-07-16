import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/core/utils/date_formatter.dart';

void main() {
  final ref = DateTime(2024, 3, 15, 14, 30);

  group('DateFormatter.date', () {
    test('formato dd/MM/yyyy', () {
      expect(DateFormatter.date(ref), '15/03/2024');
    });
  });

  group('DateFormatter.dateTime', () {
    test('incluye hora', () {
      expect(DateFormatter.dateTime(ref), '15/03/2024 14:30');
    });
  });

  group('DateFormatter.time', () {
    test('formato HH:mm', () {
      expect(DateFormatter.time(ref), '14:30');
    });
  });

  group('DateFormatter.dayMonth', () {
    test('día y mes sin ceros', () {
      expect(DateFormatter.dayMonth(ref), '15/3');
    });
  });

  group('DateFormatter.relative', () {
    test('ahora mismo retorna Ahora', () {
      expect(DateFormatter.relative(DateTime.now()), 'Ahora');
    });

    test('hace 30 minutos', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 30));
      expect(DateFormatter.relative(dt), 'Hace 30m');
    });

    test('hace 3 horas', () {
      final dt = DateTime.now().subtract(const Duration(hours: 3));
      expect(DateFormatter.relative(dt), 'Hace 3h');
    });

    test('hace 5 días retorna fecha', () {
      final dt = DateTime.now().subtract(const Duration(days: 5));
      expect(DateFormatter.relative(dt), 'Hace 5d');
    });

    test('más de 7 días retorna fecha formateada', () {
      final dt = DateTime.now().subtract(const Duration(days: 10));
      expect(DateFormatter.relative(dt), DateFormatter.date(dt));
    });
  });

  group('DateFormatter.weekdayAbbr', () {
    test('lunes = Lu', () => expect(DateFormatter.weekdayAbbr(1), 'Lu'));
    test('domingo = Do', () => expect(DateFormatter.weekdayAbbr(7), 'Do'));
    test('sábado = Sá', () => expect(DateFormatter.weekdayAbbr(6), 'Sá'));
  });
}
