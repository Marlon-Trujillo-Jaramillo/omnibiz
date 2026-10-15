import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:inventario_app/features/sales/data/mappers/sale_mapper.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/presentation/providers/sales_notifier.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';
import 'package:inventario_app/shared/providers/database_provider.dart';

class _FakeCurrentStore extends CurrentStoreNotifier {
  @override
  int? build() => 1;
}

SaleEntity _sale(DateTime createdAt) => SaleEntity(
      id: 0,
      items: const [],
      totalAmount: 100,
      taxAmount: 0,
      discountAmount: 0,
      paymentMethod: PaymentMethods.cash,
      businessContext: 'generic',
      createdAt: createdAt,
      storeId: 1,
      currencyCode: 'COP',
    );

int _n = 0;

void main() {
  late Database db;
  late ProviderContainer c;

  setUp(() async {
    db = await databaseFactoryMemory.openDatabase('sales_providers_${_n++}.db');
    for (var d = 1; d <= 7; d++) {
      await intMapStoreFactory
          .store('sales')
          .add(db, _sale(DateTime(2024, 1, d, 12)).toModel().toMap());
    }
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      currentStoreProvider.overrideWith(_FakeCurrentStore.new),
      salesPageSizeProvider.overrideWithValue(3),
    ]);
  });

  tearDown(() async {
    c.dispose();
    await db.close();
  });

  test('lastDaysRange: días calendario completos, semiabierto', () {
    final r = lastDaysRange(7, now: DateTime(2024, 3, 2, 15, 30));
    expect(r.from, DateTime(2024, 2, 25));
    expect(r.to, DateTime(2024, 3, 3));
    // Misma clave durante todo el día → el provider no recarga en cada build.
    expect(lastDaysRange(7, now: DateTime(2024, 3, 2, 0, 1)), r);
  });

  test('salesInRangeProvider sólo carga el rango pedido', () async {
    final range = (from: DateTime(2024, 1, 3), to: DateTime(2024, 1, 5));
    final sub = c.listen(salesInRangeProvider(range), (_, __) {});
    addTearDown(sub.close);
    final sales = await c.read(salesInRangeProvider(range).future);
    expect(sales.map((s) => s.createdAt.day), [4, 3]);
  });

  test('historial: primera página + loadMore hasta agotar', () async {
    const query = (from: null, paymentMethod: null);
    final provider = salesHistoryProvider(query);
    final sub = c.listen(provider, (_, __) {});
    addTearDown(sub.close);

    var state = await c.read(provider.future);
    expect(state.sales.map((s) => s.createdAt.day), [7, 6, 5]);
    expect(state.hasMore, isTrue);

    await c.read(provider.notifier).loadMore();
    await c.read(provider.notifier).loadMore();
    state = c.read(provider).requireValue;
    expect(state.sales.map((s) => s.createdAt.day), [7, 6, 5, 4, 3, 2, 1]);
    expect(state.hasMore, isFalse);

    await c.read(provider.notifier).loadMore(); // no-op
    expect(c.read(provider).requireValue.sales, hasLength(7));
  });
}
