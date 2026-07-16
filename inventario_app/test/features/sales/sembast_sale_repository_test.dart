import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:inventario_app/features/sales/data/repositories/sembast_sale_repository.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';

int _dbCounter = 0;
String _dbName() => 'sales_${_dbCounter++}.db';

SaleEntity _sale({
  int id = 0,
  String paymentMethod = 'Efectivo',
  DateTime? createdAt,
  double totalAmount = 10000,
}) =>
    SaleEntity(
      id:              id,
      items:           [
        const SaleItemEntity(
          productId:        1,
          productName:      'Producto',
          quantity:         2,
          unitPrice:        5000,
          totalPrice:       10000,
          selectedVariants: [],
        ),
      ],
      totalAmount:     totalAmount,
      taxAmount:       0,
      discountAmount:  0,
      paymentMethod:   paymentMethod,
      businessContext: 'generic',
      createdAt:       createdAt ?? DateTime.now(),
      storeId:         0,
    );

void main() {
  late SembastSaleRepository repo;
  late Database db;
  late String dbName;

  setUp(() async {
    dbName = _dbName();
    db     = await databaseFactoryMemory.openDatabase(dbName);
    repo   = SembastSaleRepository(db);
  });

  tearDown(() async {
    await db.close();
    await databaseFactoryMemory.deleteDatabase(dbName);
  });

  group('save / getAll', () {
    test('vacío inicialmente', () async {
      expect(await repo.getAll(storeId: 0), isEmpty);
    });

    test('guarda y recupera una venta', () async {
      await repo.save(_sale(totalAmount: 25000));
      final all = await repo.getAll(storeId: 0);
      expect(all, hasLength(1));
      expect(all.first.totalAmount, 25000);
    });

    test('guarda los items embebidos', () async {
      await repo.save(_sale());
      final sale = (await repo.getAll(storeId: 0)).first;
      expect(sale.items, hasLength(1));
      expect(sale.items.first.productName, 'Producto');
      expect(sale.items.first.quantity, 2);
    });

    test('método de pago se preserva', () async {
      await repo.save(_sale(paymentMethod: 'Fiado'));
      final sale = (await repo.getAll(storeId: 0)).first;
      expect(sale.paymentMethod, 'Fiado');
    });
  });

  group('getByDateRange', () {
    test('retorna ventas dentro del rango', () async {
      final d1 = DateTime(2024, 1, 10);
      final d2 = DateTime(2024, 1, 20);
      final d3 = DateTime(2024, 2, 5);

      await repo.save(_sale(createdAt: d1));
      await repo.save(_sale(createdAt: d2));
      await repo.save(_sale(createdAt: d3));

      final range = await repo.getByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
        storeId: 0,
      );
      expect(range, hasLength(2));
    });

    test('sin ventas en rango retorna lista vacía', () async {
      await repo.save(_sale(createdAt: DateTime(2024, 3, 1)));
      final range = await repo.getByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
        storeId: 0,
      );
      expect(range, isEmpty);
    });
  });
}
