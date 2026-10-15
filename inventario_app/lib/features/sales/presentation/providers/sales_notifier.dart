import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/core/utils/app_constants.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';
import 'package:inventario_app/shared/providers/database_provider.dart';

// ── Rangos de fechas ───────────────────────────────────────────────────────────

/// Intervalo semiabierto **[from, to)**. Record → igualdad por valor, apto
/// como clave de `family`.
typedef SalesRange = ({DateTime from, DateTime to});

/// Los últimos [days] días calendario, incluido hoy: desde el inicio del día
/// `hoy - (days - 1)` hasta el inicio de mañana.
///
/// Los límites caen en medianoche, así que la clave es estable durante todo
/// el día (no recarga en cada rebuild como lo haría `DateTime.now()`).
SalesRange lastDaysRange(int days, {DateTime? now}) {
  final n = now ?? DateTime.now();
  return (
    from: DateTime(n.year, n.month, n.day - (days - 1)),
    to: DateTime(n.year, n.month, n.day + 1),
  );
}

/// Ventas de la sucursal actual en un rango. Sólo carga ese rango (no todo
/// el historial). Tras una venta: `ref.invalidate(salesInRangeProvider)`.
final salesInRangeProvider = FutureProvider.autoDispose
    .family<List<SaleEntity>, SalesRange>((ref, range) {
      final storeId = ref.watch(currentStoreProvider);
      if (storeId == null) return Future.value(const []);
      return ref
          .watch(saleRepositoryProvider)
          .getByDateRange(range.from, range.to, storeId: storeId);
    });

// ── Historial paginado ─────────────────────────────────────────────────────────

/// Filtros del historial: [from] inclusivo (null = todo) y método de pago.
typedef SalesHistoryQuery = ({DateTime? from, String? paymentMethod});

class SalesHistoryState {
  const SalesHistoryState({
    required this.sales,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<SaleEntity> sales;
  final bool hasMore;
  final bool isLoadingMore;

  SalesHistoryState copyWith({
    List<SaleEntity>? sales,
    bool? hasMore,
    bool? isLoadingMore,
  }) => SalesHistoryState(
    sales: sales ?? this.sales,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

/// Tamaño de página del historial (overridable en tests).
final salesPageSizeProvider = Provider<int>((_) => AppConstants.listPageSize);

final salesHistoryProvider = AsyncNotifierProvider.autoDispose
    .family<SalesHistoryNotifier, SalesHistoryState, SalesHistoryQuery>(
  SalesHistoryNotifier.new,
);

class SalesHistoryNotifier
    extends AutoDisposeFamilyAsyncNotifier<SalesHistoryState, SalesHistoryQuery> {
  static const _tag = 'SalesHistory';

  @override
  Future<SalesHistoryState> build(SalesHistoryQuery arg) async {
    final storeId = ref.watch(currentStoreProvider);
    ref.watch(saleRepositoryProvider);
    if (storeId == null) {
      return const SalesHistoryState(sales: [], hasMore: false);
    }
    final page = await _fetch(storeId, before: null);
    return SalesHistoryState(sales: page, hasMore: page.length == _pageSize);
  }

  int get _pageSize => ref.read(salesPageSizeProvider);

  /// Carga la siguiente página y la agrega al final. No-op si no hay más o
  /// ya hay una carga en curso.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final storeId = ref.read(currentStoreProvider);
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        storeId == null ||
        current.sales.isEmpty) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _fetch(storeId, before: current.sales.last.createdAt);
      state = AsyncData(SalesHistoryState(
        sales:   [...current.sales, ...page],
        hasMore: page.length == _pageSize,
      ));
    } catch (e, st) {
      AppLogger.e(_tag, 'loadMore() falló', e, st);
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<List<SaleEntity>> _fetch(int storeId, {required DateTime? before}) {
    return ref.read(saleRepositoryProvider).getPage(
          storeId:       storeId,
          limit:         _pageSize,
          before:        before,
          from:          arg.from,
          paymentMethod: arg.paymentMethod,
        );
  }
}
