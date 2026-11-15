import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tema elegido en Ajustes (Sistema / Claro / Oscuro). Persistido igual que
/// la moneda y el tipo de negocio.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeModeNotifier([this._initial]);

  /// Valor leído en `main` antes de `runApp` (evita un parpadeo de tema).
  final ThemeMode? _initial;

  static const _key = 'omni_theme_mode';
  static const _storage = FlutterSecureStorage();

  @override
  ThemeMode build() {
    if (_initial != null) return _initial;
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final value = await readStored();
    if (value != state) state = value;
  }

  /// Tema guardado, leído fuera de Riverpod. Ante cualquier error, `system`.
  static Future<ThemeMode> readStored() async {
    try {
      return _parse(await _storage.read(key: _key));
    } catch (_) {
      return ThemeMode.system;
    }
  }

  static ThemeMode _parse(String? value) => ThemeMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => ThemeMode.system,
  );

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _key, value: mode.name);
  }
}
