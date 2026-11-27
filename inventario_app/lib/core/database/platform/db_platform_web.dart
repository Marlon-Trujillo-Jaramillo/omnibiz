import 'package:sembast_web/sembast_web.dart';

/// Fábrica de sembast respaldada por IndexedDB (navegador).
DatabaseFactory omniDatabaseFactory() => databaseFactoryWeb;

/// En el navegador no hay sistema de archivos: la BD vive en IndexedDB con su
/// nombre, sin carpeta.
Future<String> resolveOmniDbDirectory() async => '';

/// En web no existe la BD en texto plano legada ni archivos sueltos, así que
/// estas operaciones de archivo son no-ops (las ramas que las usan quedan
/// inalcanzables cuando `omniFileExists` siempre es `false`).
bool omniFileExists(String path) => false;

Future<void> omniFileDelete(String path) async {}

Future<void> omniFileRename(String from, String to) async {}
