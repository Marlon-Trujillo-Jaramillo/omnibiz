import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sembast/sembast.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/database/platform/db_platform.dart';
import 'core/database/database_error_app.dart';
import 'core/database/store_migration.dart';
import 'core/utils/app_currency.dart';
import 'core/utils/app_logger.dart';
import 'shared/providers/currency_provider.dart';
import 'shared/providers/database_provider.dart';
import 'shared/providers/theme_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La UI formatea fechas en español (DateFormat(..., 'es') en DateFormatter),
  // que necesita los datos del locale cargados antes de usarse; sin esto, la
  // primera fecha con locale lanza LocaleDataException y la pantalla queda en
  // blanco (p. ej. el grafico de ventas del dashboard).
  await initializeDateFormatting('es');

  AppLogger.i('main', 'Iniciando OmniBiz...');

  final dir = await resolveOmniDbDirectory();
  final opener = AppDatabaseOpener(
    directory: dir,
    legacyCurrencyCode: (await CurrencyNotifier.readStored()).code,
  );
  AppLogger.i('main', 'Abriendo BD cifrada en: ${opener.encryptedPath}');

  await _boot(opener, opener.open);
}

/// Abre la BD con [attempt]; si no se puede, muestra la pantalla de error
/// recuperable (nunca crea una BD vacía encima de datos existentes).
Future<void> _boot(
  AppDatabaseOpener opener,
  Future<AppDatabaseResult> Function() attempt,
) async {
  AppDatabaseResult result;
  try {
    result = await attempt();
  } catch (e, st) {
    AppLogger.e('main', 'No se pudo abrir la BD', e, st);
    result = const AppDatabaseLocked(
      'No se pudo abrir la base de datos. Tus datos no se modificaron.',
    );
  }

  switch (result) {
    case AppDatabaseReady(:final db):
      await _startApp(db);
    case AppDatabaseLocked(:final reason):
      runApp(
        DatabaseErrorApp(
          themeMode: await ThemeModeNotifier.readStored(),
          reason: reason,
          onRetry: () => _boot(opener, opener.open),
          onReset: () => _boot(opener, opener.resetUnreadable),
        ),
      );
  }
}

Future<void> _startApp(Database db) async {
  AppLogger.i('main', 'BD abierta correctamente');
  await ensureStoresMigrated(db);
  AppLogger.i('main', 'Migración de sucursales verificada');

  final themeMode = await ThemeModeNotifier.readStored();

  AppLogger.i('main', 'Lanzando ProviderScope y OmniBizApp');
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        themeModeProvider.overrideWith(() => ThemeModeNotifier(themeMode)),
      ],
      child: const OmniBizApp(),
    ),
  );
}
