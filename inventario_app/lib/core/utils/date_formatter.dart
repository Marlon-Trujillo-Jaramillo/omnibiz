import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static final _date = DateFormat('dd/MM/yyyy');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final _time = DateFormat('HH:mm');
  static final _month = DateFormat('MMMM yyyy', 'es');
  static final _short = DateFormat('dd MMM', 'es');
  static final _dayMonth = DateFormat('d/M');

  static String date(DateTime dt) => _date.format(dt);
  static String dateTime(DateTime dt) => _dateTime.format(dt);
  static String time(DateTime dt) => _time.format(dt);
  static String month(DateTime dt) => _month.format(dt);
  static String short(DateTime dt) => _short.format(dt);
  static String dayMonth(DateTime dt) => _dayMonth.format(dt);

  static String relative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return date(dt);
  }

  static String weekdayAbbr(int weekday) {
    const days = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];
    return days[(weekday - 1) % 7];
  }
}
