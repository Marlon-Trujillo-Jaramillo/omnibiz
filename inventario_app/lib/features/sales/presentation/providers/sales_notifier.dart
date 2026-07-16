import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';
import 'package:inventario_app/shared/providers/database_provider.dart';

final salesProvider =
    AsyncNotifierProvider<SalesNotifier, List<SaleEntity>>(SalesNotifier.new);

class SalesNotifier extends AsyncNotifier<List<SaleEntity>> {
  @override
  Future<List<SaleEntity>> build() {
    final storeId = ref.watch(currentStoreProvider);
    if (storeId == null) return Future.value(const []);
    return ref.watch(saleRepositoryProvider).getAll(storeId: storeId);
  }

  Future<void> refresh() => ref.refresh(salesProvider.future);
}
