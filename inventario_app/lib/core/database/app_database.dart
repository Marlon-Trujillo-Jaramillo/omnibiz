import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';
import 'package:sembast/utils/database_utils.dart';
import 'package:sembast/utils/sembast_import_export.dart';

import 'package:inventario_app/core/database/database_encryption.dart';
import 'package:inventario_app/core/database/money_migration.dart';
import 'package:inventario_app/core/utils/app_constants.dart';
import 'package:inventario_app/core/utils/app_logger.dart';

const _tag = 'AppDatabase';

/// Resultado de abrir la BD.
sealed class AppDatabaseResult {
  const AppDatabaseResult();
}

final class AppDatabaseReady extends AppDatabaseResult {
  const AppDatabaseReady(this.db);
  final Database db;
}

/// Hay un archivo cifrado pero no se puede descifrar (clave borrada del
/// almacenamiento seguro o distinta). El archivo NO se toca: el usuario
/// decide si reintentar o empezar de cero ([AppDatabaseOpener.resetUnreadable]).
final class AppDatabaseLocked extends AppDatabaseResult {
  const AppDatabaseLocked(this.reason);
  final String reason;
}

/// Abre la BD cifrada, migrando la BD en texto plano de versiones anteriores.
///
/// Archivos en [directory]:
/// - `omnibiz.db`: BD legada en texto plano (sólo existe antes de migrar).
/// - `omnibiz_enc.db`: BD cifrada (AES-GCM, [aesGcmSembastCodec]).
/// - `omnibiz_enc.db.tmp`: copia en curso; sólo se renombra a la definitiva
///   tras verificar los conteos, así que un corte a medias nunca deja una BD
///   cifrada incompleta.
class AppDatabaseOpener {
  AppDatabaseOpener({
    required this.directory,
    required this.legacyCurrencyCode,
    this.keyStore = const DatabaseKeyStore(),
    DatabaseFactory? factory,
  }) : factory = factory ?? databaseFactoryIo;

  final String directory;

  /// Moneda que se asigna a ventas antiguas sin `currencyCode` (migración v2).
  final String legacyCurrencyCode;
  final DatabaseKeyStore keyStore;
  final DatabaseFactory factory;

  static const plainName = AppConstants.dbName;
  static const encryptedName = AppConstants.encryptedDbName;

  String get plainPath => p.join(directory, plainName);
  String get encryptedPath => p.join(directory, encryptedName);
  String get _tmpPath => '$encryptedPath.tmp';

  Future<AppDatabaseResult> open() async {
    final List<int>? storedKey;
    try {
      storedKey = await keyStore.read();
    } catch (e, st) {
      AppLogger.e(_tag, 'no se pudo leer la clave', e, st);
      return const AppDatabaseLocked(
        'No se pudo leer la clave de cifrado del almacenamiento seguro.',
      );
    }

    if (File(encryptedPath).existsSync()) {
      if (storedKey == null) {
        return const AppDatabaseLocked(
          'Se encontraron datos cifrados pero falta la clave de cifrado '
          '(el almacenamiento seguro del dispositivo fue borrado).',
        );
      }
      return _openEncrypted(storedKey, cleanupPlain: true);
    }

    // Sin BD cifrada: instalación nueva o migración desde texto plano. Aquí sí
    // es seguro crear una clave nueva: no hay nada cifrado que se pierda.
    final key = storedKey ?? await keyStore.create();
    if (File(plainPath).existsSync()) {
      await _encryptPlaintext(key);
    }
    return _openEncrypted(key, cleanupPlain: false);
  }

  /// Aparta el archivo ilegible (no lo borra: renombra a
  /// `omnibiz_enc.db.unreadable-<timestamp>`), genera clave nueva y abre una
  /// BD vacía.
  Future<AppDatabaseResult> resetUnreadable() async {
    final file = File(encryptedPath);
    if (file.existsSync()) {
      final backup =
          '$encryptedPath.unreadable-${DateTime.now().millisecondsSinceEpoch}';
      await file.rename(backup);
      AppLogger.w(_tag, 'BD ilegible apartada en $backup');
    }
    final key = await keyStore.create();
    return _openEncrypted(key, cleanupPlain: false);
  }

  Future<AppDatabaseResult> _openEncrypted(
    List<int> key, {
    required bool cleanupPlain,
  }) async {
    final Database db;
    try {
      db = await factory.openDatabase(
        encryptedPath,
        codec: aesGcmSembastCodec(key),
        version: appDbVersion,
        onVersionChanged: (db, oldV, newV) => onAppDbVersionChanged(
          db,
          oldV,
          newV,
          legacyCurrencyCode: legacyCurrencyCode,
        ),
      );
    } on DatabaseException catch (e) {
      if (e.code != DatabaseException.errInvalidCodec) rethrow;
      AppLogger.e(_tag, 'clave incorrecta para la BD cifrada', e);
      return const AppDatabaseLocked(
        'La clave de cifrado no corresponde a los datos guardados.',
      );
    }
    // Restos de una migración interrumpida tras el renombrado: la BD cifrada
    // ya fue verificada, el texto plano sobra.
    if (cleanupPlain && File(plainPath).existsSync()) {
      await File(plainPath).delete();
      AppLogger.i(_tag, 'BD en texto plano residual eliminada');
    }
    return AppDatabaseReady(db);
  }

  /// Copia la BD en texto plano a una cifrada, verifica, la pone en su sitio
  /// con un rename atómico y borra el texto plano.
  Future<void> _encryptPlaintext(List<int> key) async {
    AppLogger.i(_tag, 'migrando BD en texto plano → cifrada');
    final codec = aesGcmSembastCodec(key);
    final tmp = File(_tmpPath);
    if (tmp.existsSync()) await tmp.delete();

    final plainDb = await factory.openDatabase(plainPath);
    final expected = await _countRecords(plainDb);
    final export = await exportDatabase(plainDb);
    await plainDb.close();

    final imported = await importDatabase(
      export,
      factory,
      _tmpPath,
      codec: codec,
    );
    await imported.close();

    // Verificar releyendo desde disco, con el codec.
    final check = await factory.openDatabase(_tmpPath, codec: codec);
    final actual = await _countRecords(check);
    await check.close();
    if (!_sameCounts(expected, actual)) {
      await tmp.delete();
      throw StateError(
        'Migración de cifrado: conteos distintos $expected vs $actual',
      );
    }

    await tmp.rename(encryptedPath); // atómico en el mismo sistema de archivos
    await File(plainPath).delete();
    AppLogger.i(_tag, 'BD cifrada lista: $actual');
  }

  static Future<Map<String, int>> _countRecords(Database db) async => {
    for (final name in getNonEmptyStoreNames(db))
      name: await StoreRef<Object?, Object?>(name).count(db),
  };

  static bool _sameCounts(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}
