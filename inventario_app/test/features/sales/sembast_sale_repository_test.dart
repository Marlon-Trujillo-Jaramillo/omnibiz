import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:inventario_app/features/sales/data/mappers/sale_mapper.dart';
import 'package:inventario_app/features/sales/data/repositories/sembast_sale_repository.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';

int _dbCounter = 0;
String _dbName() => 'sales_${_dbCounter++}.db';

SaleEntity _sale({
  String paymentMethod = PaymentMethods.cash,
  DateTime? createdAt,
  int totalAmount = 10000,
  int storeId = 0,
  String currencyCode = 'COP',
}) => SaleEntity(
  id: 0,
  items: [
    const SaleItemEntity(
      productId: 1,
      productName: 'Producto',
      quantity: 2,
      unitPrice: 5000,
      totalPrice: 10000,
      selectedVariants: [],
    ),
  ],
  totalAmount: totalAmount,
  taxAmount: 0,
  discountAmount: 0,
  paymentMethod: paymentMethod,
  businessContext: 'generic',
  createdAt: createdAt ?? DateTime.now(),
  storeId: storeId,
  currencyCode: currencyCode,
);

void main() {
  late SembastSaleRepository repo;
  late Database db;
  late String dbName;

  // Las ventas sólo se crean vía commitSale (que exige productos): aquí se
  // siembran directamente en el store para probar las consultas.
  Future<void> seed(SaleEntity sale) =>
      intMapStoreFactory.store('sales').add(db, sale.toModel().toMap());

  setUp(() async {
    dbName = _dbName();
    db = await databaseFactoryMemory.openDatabase(dbName);
    repo = SembastSaleRepository(db);
  });

  tearDown(() async {
    await db.close();
    await databaseFactoryMemory.deleteDatabase(dbName);
  });

  group('persistencia', () {
    test('roundtrip: centavos, items, método y moneda', () async {
      await seed(
        _sale(
          totalAmount: 2501,
          paymentMethod: PaymentMethods.credit,
          currencyCode: 'USD',
        ),
      );
      final sale = (await repo.getPage(storeId: 0, limit: 10)).single;
      expect(sale.totalAmount, 2501);
      expect(sale.paymentMethod, PaymentMethods.credit);
      expect(sale.currencyCode, 'USD');
      expect(sale.items.single.unitPrice, 5000);
      expect(sale.items.single.quantity, 2);
    });
  });

  group('getByDateRange [from, to)', () {
    test('retorna ventas dentro del rango', () async {
      await seed(_sale(createdAt: DateTime(2024, 1, 10)));
      await seed(_sale(createdAt: DateTime(2024, 1, 20)));
      await seed(_sale(createdAt: DateTime(2024, 2, 5)));

      final range = await repo.getByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 2, 1),
        storeId: 0,
      );
      expect(range, hasLength(2));
      expect(
        range.first.createdAt,
        DateTime(2024, 1, 20),
      ); // más reciente primero
    });

    test('from inclusivo, to exclusivo', () async {
      await seed(_sale(createdAt: DateTime(2024, 1, 1))); // == from
      await seed(_sale(createdAt: DateTime(2024, 1, 2))); // == to
      await seed(_sale(createdAt: DateTime(2024, 1, 1, 23, 59, 59, 999)));

      final range = await repo.getByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
        storeId: 0,
      );
      expect(range.map((s) => s.createdAt), [
        DateTime(2024, 1, 1, 23, 59, 59, 999),
        DateTime(2024, 1, 1),
      ]);
    });

    test('filtra por sucursal', () async {
      await seed(_sale(createdAt: DateTime(2024, 1, 10), storeId: 1));
      await seed(_sale(createdAt: DateTime(2024, 1, 10), storeId: 2));
      final range = await repo.getByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 2, 1),
        storeId: 1,
      );
      expect(range.single.storeId, 1);
    });

    test('sin ventas en rango retorna lista vacía', () async {
      await seed(_sale(createdAt: DateTime(2024, 3, 1)));
      final range = await repo.getByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 2, 1),
        storeId: 0,
      );
      expect(range, isEmpty);
    });
  });

  group('getPage', () {
    Future<void> seedDays(int n) async {
      for (var d = 1; d <= n; d++) {
        await seed(
          _sale(
            createdAt: DateTime(2024, 1, d),
            paymentMethod: d.isEven ? PaymentMethods.card : PaymentMethods.cash,
          ),
        );
      }
    }

    test('pagina por cursor sin duplicados ni huecos', () async {
      await seedDays(7);
      final p1 = await repo.getPage(storeId: 0, limit: 3);
      final p2 = await repo.getPage(
        storeId: 0,
        limit: 3,
        before: p1.last.createdAt,
      );
      final p3 = await repo.getPage(
        storeId: 0,
        limit: 3,
        before: p2.last.createdAt,
      );

      final days = [...p1, ...p2, ...p3].map((s) => s.createdAt.day).toList();
      expect(days, [7, 6, 5, 4, 3, 2, 1]);
      expect(p3, hasLength(1));
    });

    test('respeta from y método de pago', () async {
      await seedDays(7);
      final page = await repo.getPage(
        storeId: 0,
        limit: 10,
        from: DateTime(2024, 1, 3),
        paymentMethod: PaymentMethods.card,
      );
      expect(page.map((s) => s.createdAt.day), [6, 4]);
    });
  });
}
