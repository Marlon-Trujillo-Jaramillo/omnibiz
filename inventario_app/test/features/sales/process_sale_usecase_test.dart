import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:inventario_app/core/error/failures.dart';
import 'package:inventario_app/core/utils/app_result.dart';
import 'package:inventario_app/features/customers/data/repositories/sembast_customer_repository.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';
import 'package:inventario_app/features/inventory/data/repositories/sembast_product_repository.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/features/sales/data/repositories/sembast_sale_repository.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/domain/repositories/sale_repository.dart';
import 'package:inventario_app/features/sales/domain/usecases/process_sale_usecase.dart';

// Se prueba contra sembast en memoria (no fakes) porque lo que importa es la
// atomicidad real de la transacción.

const _store = 1;
const _otherStore = 2;

int _dbCounter = 0;

ProductEntity _product({int stock = 10, int storeId = _store}) => ProductEntity(
      id:        0,
      name:      'Producto',
      category:  'General',
      price:     5000,
      costPrice: 3000,
      stock:     stock,
      sku:       'SKU',
      variants:  [],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      storeId:   storeId,
    );

SaleItemEntity _item({int productId = 1, int quantity = 1, String name = 'Producto 1'}) =>
    SaleItemEntity(
      productId:        productId,
      productName:      name,
      quantity:         quantity,
      unitPrice:        5000,
      totalPrice:       5000 * quantity,
      selectedVariants: [],
    );

SaleEntity _sale({
  List<SaleItemEntity>? items,
  String paymentMethod = PaymentMethods.cash,
  int? customerId,
  int totalAmount = 5000,
  int storeId = _store,
}) =>
    SaleEntity(
      id:              0,
      items:           items ?? [_item()],
      totalAmount:     totalAmount,
      taxAmount:       0,
      discountAmount:  0,
      paymentMethod:   paymentMethod,
      businessContext: 'generic',
      createdAt:       DateTime.now(),
      storeId:         storeId,
      currencyCode:    'COP',
      customerId:      customerId,
    );

/// Falla al confirmar con un error no previsto (p. ej. disco lleno).
class _ThrowingSaleRepository implements SaleRepository {
  @override Future<SaleEntity> commitSale(SaleEntity sale) async => throw StateError('disco lleno');
  @override Future<List<SaleEntity>> getByDateRange(DateTime f, DateTime t, {required int storeId}) async => [];
  @override Future<List<SaleEntity>> getPage({required int storeId, required int limit, DateTime? before, DateTime? from, String? paymentMethod}) async => [];
}

Future<int> _seedPriced(SembastProductRepository repo, int priceCents) async {
  await repo.save(_product().copyWith(price: priceCents));
  return (await repo.getAll(storeId: _store)).last.id;
}

void main() {
  late Database db;
  late String dbName;
  late SembastProductRepository products;
  late SembastCustomerRepository customers;
  late SembastSaleRepository sales;
  late ProcessSaleUseCase useCase;

  Future<int> stockOf(int id) async => (await products.getById(id))!.stock;
  Future<int> debtOf(int id) async => (await customers.getById(id))!.totalDebt;
  Future<List<SaleEntity>> allSales(int storeId) =>
      sales.getPage(storeId: storeId, limit: 1000);

  setUp(() async {
    dbName    = 'process_sale_${_dbCounter++}.db';
    db        = await databaseFactoryMemory.openDatabase(dbName);
    products  = SembastProductRepository(db);
    customers = SembastCustomerRepository(db);
    sales     = SembastSaleRepository(db);
    useCase   = ProcessSaleUseCase(saleRepository: sales);

    await products.save(_product(stock: 10));                      // id 1
    await products.save(_product(stock: 1));                       // id 2
    await products.save(_product(stock: 10, storeId: _otherStore)); // id 3
    await customers.save(CustomerEntity(
        id: 0, name: 'Juan', totalDebt: 0, createdAt: DateTime(2024), storeId: _store)); // id 1
    await customers.save(CustomerEntity(
        id: 0, name: 'Ana', totalDebt: 0, createdAt: DateTime(2024), storeId: _otherStore)); // id 2
  });

  tearDown(() async {
    await db.close();
    await databaseFactoryMemory.deleteDatabase(dbName);
  });

  group('venta exitosa', () {
    test('guarda la venta y retorna el id generado (no #0)', () async {
      final result = await useCase.execute(_sale(items: [_item(quantity: 2)]));

      expect(result, isA<AppSuccess<SaleEntity>>());
      final saved = result.dataOrNull!;
      expect(saved.id, greaterThan(0));
      final all = await allSales(_store);
      expect(all.single.id, saved.id);
    });

    test('descuenta stock correctamente', () async {
      await useCase.execute(_sale(items: [_item(quantity: 3)]));

      expect(await stockOf(1), 7); // 10 - 3
    });

    test('recalcula el total desde las líneas, ignorando el de la UI', () async {
      final result = await useCase.execute(
        _sale(items: [_item(quantity: 2)], totalAmount: 1),
      );

      expect(result.dataOrNull!.totalAmount, 10000);
      expect((await allSales(_store)).single.totalAmount, 10000);
    });
  });

  group('atomicidad', () {
    test('si falla la línea 2, la línea 1 no descuenta stock', () async {
      final result = await useCase.execute(_sale(items: [
        _item(productId: 1, quantity: 3),
        _item(productId: 2, quantity: 5, name: 'Producto 2'), // solo hay 1
      ]));

      expect(result.failureOrNull, isA<StockFailure>());
      expect(await stockOf(1), 10);
      expect(await stockOf(2), 1);
      expect(await allSales(_store), isEmpty);
    });

    test('líneas duplicadas del mismo producto se suman al validar', () async {
      // 1 + 1 > stock 1 del producto 2.
      final result = await useCase.execute(_sale(items: [
        _item(productId: 2, name: 'Producto 2'),
        _item(productId: 2, name: 'Producto 2'),
      ]));

      expect(result.failureOrNull, isA<StockFailure>());
      expect(await stockOf(2), 1);
    });

    test('líneas duplicadas válidas descuentan la suma', () async {
      final result = await useCase.execute(_sale(items: [
        _item(quantity: 2),
        _item(quantity: 3),
      ]));

      expect(result, isA<AppSuccess<SaleEntity>>());
      expect(await stockOf(1), 5);
    });

    test('Fiado rechazado no deja deuda escrita', () async {
      final result = await useCase.execute(_sale(
        items: [_item(productId: 1), _item(productId: 2, quantity: 9, name: 'Producto 2')],
        paymentMethod: PaymentMethods.credit,
        customerId: 1,
      ));

      expect(result.failureOrNull, isA<StockFailure>());
      expect(await debtOf(1), 0);
      expect(await stockOf(1), 10);
    });

    test('error inesperado al confirmar → DatabaseFailure', () async {
      final result = await ProcessSaleUseCase(saleRepository: _ThrowingSaleRepository())
          .execute(_sale());

      expect(result.failureOrNull, isA<DatabaseFailure>());
    });
  });

  group('stock insuficiente', () {
    test('retorna StockFailure sin guardar la venta', () async {
      final result = await useCase.execute(_sale(items: [_item(quantity: 999)]));

      expect(result.failureOrNull, isA<StockFailure>());
      expect(await allSales(_store), isEmpty);
    });

    test('mensaje menciona el producto', () async {
      final result = await useCase.execute(_sale(items: [_item(quantity: 999)]));

      expect(result.failureOrNull!.message, contains('Producto 1'));
    });
  });

  group('producto no encontrado', () {
    test('retorna NotFoundFailure', () async {
      final result = await useCase.execute(_sale(items: [_item(productId: 999)]));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('sucursal', () {
    test('producto de otra sucursal → ValidationFailure sin tocar stock', () async {
      final result = await useCase.execute(_sale(items: [_item(productId: 3)]));

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await stockOf(3), 10);
    });

    test('storeId 0 → ValidationFailure', () async {
      final result = await useCase.execute(_sale(storeId: 0));

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('carrito vacío → ValidationFailure', () async {
      final result = await useCase.execute(_sale(items: []));

      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('pago Fiado', () {
    test('suma deuda al cliente', () async {
      await useCase.execute(_sale(
        items: [_item(quantity: 3)],
        paymentMethod: PaymentMethods.credit,
        customerId: 1,
      ));

      expect(await debtOf(1), 15000);
    });

    test('fiados con céntimos + pago completo → deuda exactamente 0', () async {
      // Precios de USD 0.10 y 0.20 (en double: 0.1 + 0.2 = 0.30000000000000004).
      final p10 = await _seedPriced(products, 10);
      final p20 = await _seedPriced(products, 20);
      for (final pid in [p10, p20, p10]) {
        final result = await useCase.execute(_sale(
          items: [
            SaleItemEntity(
              productId: pid, productName: 'P$pid', quantity: 1,
              unitPrice: pid == p10 ? 10 : 20, totalPrice: 0,
              selectedVariants: const [],
            ),
          ],
          paymentMethod: PaymentMethods.credit,
          customerId: 1,
        ));
        expect(result.isSuccess, isTrue);
      }
      expect(await debtOf(1), 40);

      await customers.registerPayment(1, 40);
      expect(await debtOf(1), 0);
      expect((await customers.getById(1))!.hasDebt, isFalse);
    });

    test('sin customerId → ValidationFailure y no se guarda nada', () async {
      final result = await useCase.execute(
        _sale(paymentMethod: PaymentMethods.credit, customerId: null),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await stockOf(1), 10);
      expect(await allSales(_store), isEmpty);
    });

    test('cliente inexistente → ValidationFailure', () async {
      final result = await useCase.execute(
        _sale(paymentMethod: PaymentMethods.credit, customerId: 999),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await stockOf(1), 10);
    });

    test('cliente de otra sucursal → ValidationFailure', () async {
      final result = await useCase.execute(
        _sale(paymentMethod: PaymentMethods.credit, customerId: 2),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await debtOf(2), 0);
    });
  });
}
