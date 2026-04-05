import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:inventario_app/core/isar_provider.dart';
import 'package:inventario_app/models/sale_model.dart';

final salesProvider = StateNotifierProvider<SalesNotifier, List<Sale>>((ref) {
  final isar = ref.watch(isarProvider);
  return SalesNotifier(isar);
});

class SalesNotifier extends StateNotifier<List<Sale>> {
  final Isar _isar;

  SalesNotifier(this._isar) : super([]) {
    _loadSales();
  }

  Future<void> _loadSales() async {
    state = await _isar.sales.where().sortByCreatedAtDesc().findAll();
  }

  Future<void> refresh() async {
    await _loadSales();
  }

  // Helper for dashboard analytics
  Map<String, double> getDailySales(int days) {
    // Current date logic simplification
    final now = DateTime.now();
    final Map<String, double> data = {};

    // Last 7 days aggregation
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dayKey = '${date.day}/${date.month}';
      data[dayKey] = 0.0;
    }

    for (var sale in state) {
      final saleDate = '${sale.createdAt.day}/${sale.createdAt.month}';
      if (data.containsKey(saleDate)) {
        data[saleDate] = (data[saleDate] ?? 0.0) + sale.totalAmount;
      }
    }

    return data;
  }
}
