import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:inventario_app/core/database/money_migration.dart';
import 'package:inventario_app/features/customers/data/models/customer_model.dart';
import 'package:inventario_app/features/inventory/data/models/product_model.dart';
import 'package:inventario_app/features/sales/data/models/sale_model.dart';

final _products  = intMapStoreFactory.store('products');
final _sales     = intMapStoreFactory.store('sales');
final _customers = intMapStoreFactory.store('customers');

int _n = 0;

/// BD v1 (legado): montos como double en unidades mayores, ventas sin moneda.
Future<String> _seedV1() async {
  final name = 'money_${_n++}.db';
  final db = await databaseFactoryMemory.openDatabase(name, version: 1);
  await _products.add(db, {
    'name': 'Café', 'category': 'General', 'price': 10.005, 'costPrice': 2.5,
    'stock': 3, 'sku': 'S', 'barcode': null, 'variants': <String>[],
    'createdAt': '2024-01-01T00:00:00.000', 'updatedAt': '2024-01-01T00:00:00.000',
    'storeId': 1,
  });
  await _customers.add(db, {
    'name': 'Ana', 'phone': null, 'email': null,
    'totalDebt': 0.1 + 0.2, // 0.30000000000000004
    'createdAt': '2024-01-01T00:00:00.000', 'lastTransaction': null, 'storeId': 1,
  });
  await _customers.add(db, {
    'name': 'Luis', 'phone': null, 'email': null,
    'totalDebt': 1e-12, // deuda "fantasma" tras pagos con float
    'createdAt': '2024-01-01T00:00:00.000', 'lastTransaction': null, 'storeId': 1,
  });
  await _sales.add(db, {
    'items': [
      {'productId': 1, 'productName': 'Café', 'quantity': 3,
       'unitPrice': 10.005, 'totalPrice': 30.015, 'selectedVariants': <String>[]},
    ],
    'totalAmount': 30.015, 'taxAmount': 0.0, 'discountAmount': 0.0,
    'createdAt': '2024-01-01T10:00:00.000', 'paymentMethod': 'Efectivo',
    'customerId': null, 'businessContext': 'generic', 'storeId': 1,
  });
  await db.close();
  return name;
}

Future<Database> _openV2(String name, {String legacy = 'USD'}) =>
    databaseFactoryMemory.openDatabase(
      name,
      version: appDbVersion,
      onVersionChanged: (db, o, n) =>
          onAppDbVersionChanged(db, o, n, legacyCurrencyCode: legacy),
    );

void main() {
  test('v1 → v2 convierte montos a centavos (redondeo mitad arriba)', () async {
    final db = await _openV2(await _seedV1());

    final product = Product.fromMap(1, (await _products.record(1).get(db))!);
    expect(product.price, 1001);
    expect(product.costPrice, 250);

    final ana  = Customer.fromMap(1, (await _customers.record(1).get(db))!);
    final luis = Customer.fromMap(2, (await _customers.record(2).get(db))!);
    expect(ana.totalDebt, 30);
    expect(luis.totalDebt, 0);

    final sale = Sale.fromMap(1, (await _sales.record(1).get(db))!);
    expect(sale.totalAmount, 3002); // 30.015 → 3002
    expect(sale.items.single.unitPrice, 1001);
    expect(sale.items.single.totalPrice, 3002);
    expect(sale.items.single.productName, 'Café');
    expect(sale.currencyCode, 'USD');
    expect(db.version, appDbVersion);
    await db.close();
  });

  test('idempotente: reabrir o reinvocar no vuelve a multiplicar', () async {
    final name = await _seedV1();
    var db = await _openV2(name);
    expect(await migrateMoneyToMinorUnits(db, legacyCurrencyCode: 'COP'), isFalse);
    await db.close();

    db = await _openV2(name);
    expect((await _products.record(1).get(db))!['price'], 1001);
    await db.close();
  });

  test('BD nueva (versión 0) no ejecuta la conversión', () async {
    final db = await _openV2('money_new_${_n++}.db');
    await _products.add(db, {'price': 500});
    expect((await _products.record(1).get(db))!['price'], 500);
    await db.close();
  });

  test('una venta que ya tenía moneda la conserva', () async {
    final name = 'money_${_n++}.db';
    var db = await databaseFactoryMemory.openDatabase(name, version: 1);
    await _sales.add(db, {
      'items': <Object>[], 'totalAmount': 1.0, 'taxAmount': 0, 'discountAmount': 0,
      'currencyCode': 'COP',
    });
    await db.close();
    db = await _openV2(name, legacy: 'USD');
    final v = (await _sales.record(1).get(db))!;
    expect(v['currencyCode'], 'COP');
    expect(v['totalAmount'], 100);
    await db.close();
  });
}
