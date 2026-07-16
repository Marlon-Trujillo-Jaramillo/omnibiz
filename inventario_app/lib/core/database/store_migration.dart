import 'package:sembast/sembast.dart';
import 'package:inventario_app/core/utils/app_logger.dart';

const _tag = 'StoreMigration';

/// Garantiza que exista al menos una sucursal y asigna [storeId] a los
/// registros de productos/categorías/ventas/clientes creados antes de la
/// introducción de multi-sucursal. Idempotente: seguro de correr en cada arranque.
Future<int> ensureStoresMigrated(Database db) async {
  final storesStore = intMapStoreFactory.store('stores');
  final existing = await storesStore.find(db);

  final int defaultStoreId;
  if (existing.isNotEmpty) {
    existing.sort((a, b) => a.key.compareTo(b.key));
    defaultStoreId = existing.first.key;
  } else {
    defaultStoreId = await storesStore.add(db, {
      'name': 'Sucursal Principal',
      'icon': 'store',
      'address': null,
      'createdAt': DateTime.now().toIso8601String(),
    });
    AppLogger.i(_tag, 'Sucursal por defecto creada id=$defaultStoreId');
  }

  for (final storeName in ['products', 'categories', 'sales', 'customers']) {
    final store = intMapStoreFactory.store(storeName);
    final snapshots = await store.find(
      db,
      finder: Finder(filter: Filter.equals('storeId', null)),
    );
    if (snapshots.isEmpty) continue;

    await db.transaction((txn) async {
      for (final s in snapshots) {
        await store.record(s.key).update(txn, {'storeId': defaultStoreId});
      }
    });
    AppLogger.i(_tag, 'Backfill: ${snapshots.length} registros en "$storeName" → storeId=$defaultStoreId');
  }

  return defaultStoreId;
}
