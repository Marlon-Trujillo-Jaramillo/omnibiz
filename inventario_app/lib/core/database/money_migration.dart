import 'package:sembast/sembast.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/core/utils/money.dart';

const _tag = 'MoneyMigration';

/// Versión del esquema sembast.
///
/// - 1: montos como `double` en unidades mayores (legado).
/// - 2: montos como `int` en centavos ([Money]) + `currencyCode` por venta.
const appDbVersion = 2;

final _meta = StoreRef<String, Object?>('app_meta');
const _moneyMarker = 'money_minor_units';

/// `onVersionChanged` de la BD. Corre dentro de la transacción de apertura de
/// sembast: si falla, ni los datos ni la versión cambian.
Future<void> onAppDbVersionChanged(
  Database db,
  int oldVersion,
  int newVersion, {
  required String legacyCurrencyCode,
}) async {
  AppLogger.i(_tag, 'versión BD $oldVersion → $newVersion');
  // 0 = BD nueva: no hay nada que migrar.
  if (oldVersion >= 1 && oldVersion < 2) {
    await migrateMoneyToMinorUnits(db, legacyCurrencyCode: legacyCurrencyCode);
  }
}

/// Convierte los montos `double` (unidades mayores) de productos, ventas (con
/// sus líneas) y clientes a `int` en centavos, redondeando la mitad hacia
/// arriba. Rellena `currencyCode` en ventas que no lo tengan con
/// [legacyCurrencyCode] (la moneda configurada cuando se hicieron).
///
/// Idempotente: deja una marca en `app_meta` y no vuelve a convertir.
/// Devuelve `false` si ya estaba migrada.
Future<bool> migrateMoneyToMinorUnits(
  Database db, {
  required String legacyCurrencyCode,
}) {
  return db.transaction((txn) async {
    if (await _meta.record(_moneyMarker).get(txn) == true) return false;

    final counts = <String, int>{};
    counts['products'] = await _convertStore(
      txn,
      'products',
      (v) => {'price': _cents(v['price']), 'costPrice': _cents(v['costPrice'])},
    );
    counts['customers'] = await _convertStore(
      txn,
      'customers',
      (v) => {'totalDebt': _cents(v['totalDebt'])},
    );
    counts['sales'] = await _convertStore(
      txn,
      'sales',
      (v) => {
        'totalAmount': _cents(v['totalAmount']),
        'taxAmount': _cents(v['taxAmount']),
        'discountAmount': _cents(v['discountAmount']),
        'items': [
          for (final item in (v['items'] as List? ?? const []))
            {
              ...(item as Map).cast<String, Object?>(),
              'unitPrice': _cents(item['unitPrice']),
              'totalPrice': _cents(item['totalPrice']),
            },
        ],
        if (v['currencyCode'] == null) 'currencyCode': legacyCurrencyCode,
      },
    );

    await _meta.record(_moneyMarker).put(txn, true);
    AppLogger.i(_tag, 'montos convertidos a centavos: $counts');
    return true;
  });
}

Future<int> _convertStore(
  Transaction txn,
  String storeName,
  Map<String, Object?> Function(Map<String, Object?> value) changes,
) async {
  final store = intMapStoreFactory.store(storeName);
  final snapshots = await store.find(txn);
  for (final s in snapshots) {
    await store.record(s.key).update(txn, changes(s.value));
  }
  return snapshots.length;
}

/// Montos ausentes/nulos → 0 (registros corruptos no deben bloquear el arranque).
int _cents(Object? legacy) =>
    legacy is num ? Money.fromDouble(legacy.toDouble()) : 0;
