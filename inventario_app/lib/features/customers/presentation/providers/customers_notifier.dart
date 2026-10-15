import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';
import 'package:inventario_app/shared/providers/database_provider.dart';

final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<CustomerEntity>>(
  CustomersNotifier.new,
);

class CustomersNotifier extends AsyncNotifier<List<CustomerEntity>> {
  static const _tag = 'CustomersNotifier';

  @override
  Future<List<CustomerEntity>> build() {
    final storeId = ref.watch(currentStoreProvider);
    AppLogger.d(_tag, 'build() → cargando clientes storeId=$storeId');
    if (storeId == null) return Future.value(const []);
    return ref.watch(customerRepositoryProvider).getAll(storeId: storeId);
  }

  Future<void> add(CustomerEntity customer) async {
    AppLogger.i(_tag, 'add() "${customer.name}"');
    await ref.read(customerRepositoryProvider).save(customer);
    ref.invalidateSelf();
    AppLogger.i(_tag, 'add() → ok');
  }

  Future<void> registerPayment(int customerId, int amount) async {
    AppLogger.i(_tag, 'registerPayment(id=$customerId, amount=$amount)');
    await ref.read(customerRepositoryProvider).registerPayment(customerId, amount);
    ref.invalidateSelf();
    AppLogger.i(_tag, 'registerPayment() → ok');
  }

  Future<void> delete(int id) async {
    AppLogger.i(_tag, 'delete($id)');
    await ref.read(customerRepositoryProvider).delete(id);
    ref.invalidateSelf();
    AppLogger.i(_tag, 'delete($id) → ok');
  }
}
