import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// Fábrica de sembast respaldada por archivos (móvil/escritorio).
DatabaseFactory omniDatabaseFactory() => databaseFactoryIo;

/// Carpeta donde viven los archivos de la BD.
Future<String> resolveOmniDbDirectory() async =>
    (await getApplicationDocumentsDirectory()).path;

bool omniFileExists(String path) => File(path).existsSync();

Future<void> omniFileDelete(String path) async {
  final file = File(path);
  if (file.existsSync()) await file.delete();
}

Future<void> omniFileRename(String from, String to) async {
  await File(from).rename(to);
}
