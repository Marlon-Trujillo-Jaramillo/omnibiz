import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/core/error/failures.dart';
import 'package:inventario_app/core/utils/app_result.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';
import 'package:inventario_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/features/inventory/domain/repositories/product_repository.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/domain/repositories/sale_repository.dart';
import 'package:inventario_app/features/sales/domain/usecases/process_sale_usecase.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class FakeProductRepository implements ProductRepository {
  final Map<int, ProductEntity> _products;
  final Map<int, int> stockUpdates = {};

  FakeProductRepository(List<ProductEntity> products)
      : _products = {for (final p in products) p.id: p};

  @override Future<ProductEntity?> getById(int id) async => _products[id];

  @override Future<void> updateStock(int id, int newStock) async {
    stockUpdates[id] = newStock;
    final p = _products[id]!;
    _products[id] = p.copyWith(stock: newStock);
  }

  @override Future<List<ProductEntity>> getAll({int storeId = 0}) async => _products.values.toList();
  @override Future<ProductEntity?> getByBarcode(String b, {int storeId = 0}) async => null;
  @override Future<ProductEntity?> getBySku(String s, {int storeId = 0}) async => null;
  @override Future<void> save(ProductEntity p) async {}
  @override Future<void> delete(int id) async {}
  @override Stream<List<ProductEntity>> watchAll({int storeId = 0}) => const Stream.empty();
  @override Future<List<CategoryEntity>> getAllCategories({int storeId = 0}) async => [];
  @override Future<void> saveCategory(CategoryEntity c) async {}
  @override Future<void> deleteCategory(int id) async {}
}

class FakeSaleRepository implements SaleRepository {
  final List<SaleEntity> saved = [];

  @override Future<void> save(SaleEntity sale) async => saved.add(sale);
  @override Future<List<SaleEntity>> getAll({int storeId = 0}) async => saved;
  @override Future<List<SaleEntity>> getByDateRange(DateTime f, DateTime t, {int storeId = 0}) async => [];
  @override Stream<List<SaleEntity>> watchAll({int storeId = 0}) => const Stream.empty();
}

class FakeCustomerRepository implements CustomerRepository {
  final Map<int, CustomerEntity> _customers;
  final Map<int, double> debtDeltas = {};

  FakeCustomerRepository(List<CustomerEntity> customers)
      : _customers = {for (final c in customers) c.id: c};

  @override Future<CustomerEntity?> getById(int id) async => _customers[id];

  @override Future<void> updateDebt(int id, double delta) async {
    debtDeltas[id] = (debtDeltas[id] ?? 0) + delta;
  }

  @override Future<List<CustomerEntity>> getAll({int storeId = 0}) async => _customers.values.toList();
  @override Future<void> save(CustomerEntity c) async {}
  @override Future<void> delete(int id) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProductEntity _product({int id = 1, int stock = 10}) => ProductEntity(
      id:        id,
      name:      'Producto $id',
      category:  'General',
      price:     5000,
      costPrice: 3000,
      stock:     stock,
      sku:       'SKU-$id',
      variants:  [],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      storeId:   0,
    );

SaleItemEntity _item({int productId = 1, int quantity = 1}) => SaleItemEntity(
      productId:        productId,
      productName:      'Producto $productId',
      quantity:         quantity,
      unitPrice:        5000,
      totalPrice:       5000.0 * quantity,
      selectedVariants: [],
    );

SaleEntity _sale({
  List<SaleItemEntity>? items,
  String paymentMethod = 'Efectivo',
  int? customerId,
}) =>
    SaleEntity(
      id:              0,
      items:           items ?? [_item()],
      totalAmount:     5000,
      taxAmount:       0,
      discountAmount:  0,
      paymentMethod:   paymentMethod,
      businessContext: 'generic',
      createdAt:       DateTime.now(),
      storeId:         0,
      customerId:      customerId,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeProductRepository products;
  late FakeSaleRepository     sales;
  late FakeCustomerRepository customers;
  late ProcessSaleUseCase     useCase;

  setUp(() {
    products  = FakeProductRepository([_product(id: 1, stock: 10)]);
    sales     = FakeSaleRepository();
    customers = FakeCustomerRepository([
      CustomerEntity(
          id: 99, name: 'Juan', totalDebt: 0, createdAt: DateTime(2024), storeId: 0),
    ]);
    useCase = ProcessSaleUseCase(
      saleRepository:     sales,
      productRepository:  products,
      customerRepository: customers,
    );
  });

  group('venta exitosa', () {
    test('guarda la venta y retorna sin failure', () async {
      final result = await useCase.execute(_sale(items: [_item(quantity: 2)]));

      expect(result, isA<AppSuccess<SaleEntity>>());
      expect(sales.saved, hasLength(1));
    });

    test('descuenta stock correctamente', () async {
      await useCase.execute(_sale(items: [_item(quantity: 3)]));

      expect(products.stockUpdates[1], 7); // 10 - 3
    });
  });

  group('stock insuficiente', () {
    test('retorna StockFailure sin guardar la venta', () async {
      final result = await useCase.execute(
        _sale(items: [_item(quantity: 999)]),
      );

      expect(result, isA<AppFailure<SaleEntity>>());
      expect((result as AppFailure<SaleEntity>).failure, isA<StockFailure>());
      expect(sales.saved, isEmpty);
    });

    test('mensaje menciona el producto', () async {
      final result = await useCase.execute(
        _sale(items: [_item(quantity: 999)]),
      );

      expect((result as AppFailure<SaleEntity>).failure.message, contains('Producto 1'));
    });
  });

  group('producto no encontrado', () {
    test('retorna NotFoundFailure', () async {
      final result = await useCase.execute(
        _sale(items: [_item(productId: 999)]),
      );

      expect(result, isA<AppFailure<SaleEntity>>());
      expect((result as AppFailure<SaleEntity>).failure, isA<NotFoundFailure>());
    });
  });

  group('pago Fiado', () {
    test('suma deuda al cliente', () async {
      const total = 15000.0;
      await useCase.execute(
        SaleEntity(
          id:              0,
          items:           [_item()],
          totalAmount:     total,
          taxAmount:       0,
          discountAmount:  0,
          paymentMethod:   'Fiado',
          businessContext: 'generic',
          createdAt:       DateTime.now(),
          storeId:         0,
          customerId:      99,
        ),
      );

      expect(customers.debtDeltas[99], total);
    });

    test('sin customerId no actualiza deuda', () async {
      await useCase.execute(
        _sale(paymentMethod: 'Fiado', customerId: null),
      );

      expect(customers.debtDeltas, isEmpty);
    });
  });
}
