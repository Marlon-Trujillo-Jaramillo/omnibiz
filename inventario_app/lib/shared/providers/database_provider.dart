import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:inventario_app/features/customers/data/repositories/sembast_customer_repository.dart';
import 'package:inventario_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:inventario_app/features/inventory/data/repositories/sembast_product_repository.dart';
import 'package:inventario_app/features/inventory/domain/repositories/product_repository.dart';
import 'package:inventario_app/features/sales/data/repositories/sembast_sale_repository.dart';
import 'package:inventario_app/features/sales/domain/repositories/sale_repository.dart';
import 'package:inventario_app/features/sales/domain/usecases/process_sale_usecase.dart';
import 'package:inventario_app/features/stores/data/repositories/sembast_store_repository.dart';
import 'package:inventario_app/features/stores/domain/repositories/store_repository.dart';

// ── Sembast instance (injected from main.dart) ────────────────────────────────
final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError(
      'Provide Database via ProviderScope overrides in main.dart');
});

// ── Repository providers ───────────────────────────────────────────────────────
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SembastProductRepository(ref.watch(databaseProvider));
});

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SembastSaleRepository(ref.watch(databaseProvider));
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return SembastCustomerRepository(ref.watch(databaseProvider));
});

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return SembastStoreRepository(ref.watch(databaseProvider));
});

// ── Use case providers ─────────────────────────────────────────────────────────
final processSaleUseCaseProvider = Provider<ProcessSaleUseCase>((ref) {
  return ProcessSaleUseCase(
    saleRepository:     ref.watch(saleRepositoryProvider),
    productRepository:  ref.watch(productRepositoryProvider),
    customerRepository: ref.watch(customerRepositoryProvider),
  );
});
