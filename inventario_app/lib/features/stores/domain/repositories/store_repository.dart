import '../entities/store_entity.dart';

abstract interface class StoreRepository {
  Future<List<StoreEntity>> getAll();
  Future<StoreEntity?> getById(int id);
  Future<void> save(StoreEntity store);

  /// Elimina la sucursal (y sus categorías). Lanza [StoreInUseException] si
  /// aún tiene productos, ventas o clientes: nunca deja datos huérfanos.
  Future<void> delete(int id);
  Stream<List<StoreEntity>> watchAll();
}

class StoreInUseException implements Exception {
  const StoreInUseException({
    required this.products,
    required this.sales,
    required this.customers,
  });

  final int products;
  final int sales;
  final int customers;

  String get message {
    final parts = [
      if (products > 0) '$products producto(s)',
      if (sales > 0) '$sales venta(s)',
      if (customers > 0) '$customers cliente(s)',
    ];
    return 'No se puede eliminar: la sucursal aún tiene ${parts.join(', ')}.';
  }

  @override
  String toString() => 'StoreInUseException: $message';
}
