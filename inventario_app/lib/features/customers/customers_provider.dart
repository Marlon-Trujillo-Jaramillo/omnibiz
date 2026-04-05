import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:inventario_app/core/isar_provider.dart';
import 'package:inventario_app/models/customer_model.dart';

final customersProvider =
    StateNotifierProvider<CustomersNotifier, List<Customer>>((ref) {
      final isar = ref.watch(isarProvider);
      return CustomersNotifier(isar);
    });

class CustomersNotifier extends StateNotifier<List<Customer>> {
  final Isar _isar;

  CustomersNotifier(this._isar) : super([]) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = await _isar.customers.where().findAll();
  }

  Future<void> addCustomer(Customer customer) async {
    await _isar.writeTxn(() async {
      await _isar.customers.put(customer);
    });
    await loadCustomers();
  }

  Future<void> updateDebt(int customerId, double amount) async {
    final customer = await _isar.customers.get(customerId);
    if (customer != null) {
      customer.totalDebt += amount;
      customer.lastTransaction = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.customers.put(customer);
      });
      await loadCustomers();
    }
  }

  Future<void> deleteCustomer(int customerId) async {
    await _isar.writeTxn(() async {
      await _isar.customers.delete(customerId);
    });
    await loadCustomers();
  }
}
