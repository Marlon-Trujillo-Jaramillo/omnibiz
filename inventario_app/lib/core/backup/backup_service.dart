import 'dart:typed_data';

import 'package:sembast/sembast_memory.dart';
import 'package:sembast/utils/database_utils.dart';
import 'package:sembast/utils/sembast_import_export.dart';

import 'package:inventario_app/core/backup/backup_codec.dart';
import 'package:inventario_app/core/database/money_migration.dart';
import 'package:inventario_app/core/database/store_migration.dart';
import 'package:inventario_app/core/utils/app_logger.dart';

const _tag = 'BackupService';

/// Cuántos registros quedaron de cada tipo tras restaurar.
class RestoreSummary {
  const RestoreSummary({required this.counts, required this.defaultStoreId});

  /// Registros por store de sembast (`products`, `sales`, `customers`…).
  final Map<String, int> counts;

  /// Primera sucursal del respaldo: la que debe quedar activa.
  final int defaultStoreId;

  int count(String store) => counts[store] ?? 0;
}

/// Crea y restaura respaldos cifrados de toda la base de datos.
class BackupService {
  BackupService(this._db, {BackupCodec codec = const BackupCodec()})
    : _codec = codec;

  final Database _db;
  final BackupCodec _codec;

  Future<Uint8List> create(String password) async {
    final data = await exportDatabase(_db);
    AppLogger.i(_tag, 'create(): ${_countRecordsIn(data)} registros');
    return _codec.encode(data, password, schemaVersion: appDbVersion);
  }

  /// Reemplaza TODOS los datos por los del respaldo, en una sola transacción.
  ///
  /// 1. Descifra (contraseña incorrecta → excepción, sin tocar nada).
  /// 2. Importa a una BD **en memoria** y le aplica las mismas migraciones
  ///    de esquema que al arrancar, así un respaldo antiguo sigue sirviendo.
  /// 3. Copia el resultado sobre la BD real dentro de `db.transaction`: o queda
  ///    todo restaurado o no cambia nada.
  Future<RestoreSummary> restore(
    Uint8List bytes,
    String password, {
    required String legacyCurrencyCode,
  }) async {
    final content = await _codec.decode(bytes, password);
    final version = content.data['version'];
    if (version is int && version > appDbVersion) {
      throw const BackupTooNewException();
    }

    final staging = await _openMigratedCopy(
      content.data,
      legacyCurrencyCode: legacyCurrencyCode,
    );
    try {
      final defaultStoreId = await ensureStoresMigrated(staging);
      final source = {
        for (final name in getNonEmptyStoreNames(staging))
          name: await StoreRef<Object?, Object?>(name).find(staging),
      };

      await _db.transaction((txn) async {
        final names = {...getNonEmptyStoreNames(_db), ...source.keys};
        for (final name in names) {
          final store = StoreRef<Object?, Object?>(name);
          await store.delete(txn);
          for (final record in source[name] ?? const []) {
            await store.record(record.key).put(txn, record.value);
          }
        }
      });

      final counts = {
        for (final entry in source.entries) entry.key: entry.value.length,
      };
      AppLogger.i(_tag, 'restore() → $counts');
      return RestoreSummary(counts: counts, defaultStoreId: defaultStoreId);
    } finally {
      await staging.close();
      await databaseFactoryMemory.deleteDatabase(staging.path);
    }
  }

  static int _stagingCounter = 0;

  Future<Database> _openMigratedCopy(
    Map<String, Object?> export, {
    required String legacyCurrencyCode,
  }) async {
    final name = 'omnibiz_restore_${_stagingCounter++}.db';
    final factory = databaseFactoryMemory;
    final imported = await importDatabase(export, factory, name);
    await imported.close();
    return factory.openDatabase(
      name,
      version: appDbVersion,
      onVersionChanged: (db, oldV, newV) => onAppDbVersionChanged(
        db,
        oldV,
        newV,
        legacyCurrencyCode: legacyCurrencyCode,
      ),
    );
  }

  static int _countRecordsIn(Map<String, Object?> export) {
    final stores = export['stores'];
    if (stores is! List) return 0;
    return stores.fold<int>(
      0,
      (sum, s) => sum + (((s as Map)['keys'] as List?)?.length ?? 0),
    );
  }
}
