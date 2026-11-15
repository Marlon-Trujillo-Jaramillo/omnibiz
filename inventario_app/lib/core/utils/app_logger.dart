import 'package:flutter/foundation.dart';

enum _Level { debug, info, warn, error }

abstract final class AppLogger {
  static void d(String tag, String msg) => _log(_Level.debug, tag, msg);
  static void i(String tag, String msg) => _log(_Level.info, tag, msg);
  static void w(String tag, String msg) => _log(_Level.warn, tag, msg);
  static void e(String tag, String msg, [Object? err, StackTrace? st]) {
    _log(_Level.error, tag, msg);
    if (err != null) debugPrint('   ↳ ERROR: $err');
    if (st != null) debugPrint('   ↳ STACK:\n$st');
  }

  static void _log(_Level level, String tag, String msg) {
    if (!kDebugMode) return;
    final time = _ts();
    final prefix = switch (level) {
      _Level.debug => '🔍 DBG',
      _Level.info => '📋 INF',
      _Level.warn => '⚠️  WRN',
      _Level.error => '🔴 ERR',
    };
    debugPrint('[$time][$prefix][$tag] $msg');
  }

  static String _ts() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
  }
}
