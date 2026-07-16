import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';

import 'app/app.dart';
import 'core/database/store_migration.dart';
import 'core/utils/app_constants.dart';
import 'core/utils/app_logger.dart';
import 'shared/providers/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.i('main', 'Iniciando OmniBiz...');

  final dir  = await getApplicationDocumentsDirectory();
  final path = join(dir.path, AppConstants.dbName);
  AppLogger.i('main', 'Abriendo BD en: $path');

  final db = await databaseFactoryIo.openDatabase(path);
  AppLogger.i('main', 'BD abierta correctamente');

  await ensureStoresMigrated(db);
  AppLogger.i('main', 'Migración de sucursales verificada');

  AppLogger.i('main', 'Lanzando ProviderScope y OmniBizApp');
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const OmniBizApp(),
    ),
  );
}
