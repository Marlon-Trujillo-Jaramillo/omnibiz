import '../entities/sale_entity.dart';

abstract interface class SaleRepository {
  /// Ventas con `createdAt` en el intervalo semiabierto **[from, to)**,
  /// de la más reciente a la más antigua.
  Future<List<SaleEntity>> getByDateRange(
    DateTime from,
    DateTime to, {
    required int storeId,
  });

  /// Página de ventas (más recientes primero) para listas largas.
  ///
  /// Paginación por cursor: [before] es el `createdAt` de la última venta de
  /// la página anterior (exclusivo). [from] (inclusivo) y [paymentMethod]
  /// filtran opcionalmente.
  Future<List<SaleEntity>> getPage({
    required int storeId,
    required int limit,
    DateTime? before,
    DateTime? from,
    String? paymentMethod,
  });

  /// Confirma una venta de forma atómica: valida stock (agregando líneas del
  /// mismo producto), descuenta stock, suma deuda si es Fiado y guarda la
  /// venta — todo o nada. Devuelve la venta con su id generado.
  ///
  /// Lanza una [SaleRejection] si la venta no es válida; en ese caso no se
  /// escribe nada.
  Future<SaleEntity> commitSale(SaleEntity sale);
}

/// Motivo de rechazo de [SaleRepository.commitSale]. Se lanza dentro de la
/// transacción para revertirla; el caso de uso lo traduce a un `Failure`.
sealed class SaleRejection implements Exception {
  const SaleRejection(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class ProductNotFoundRejection extends SaleRejection {
  const ProductNotFoundRejection(super.message);
}

final class InsufficientStockRejection extends SaleRejection {
  const InsufficientStockRejection(super.message);
}

/// Datos inconsistentes: producto o cliente de otra sucursal, cliente inexistente.
final class InvalidSaleRejection extends SaleRejection {
  const InvalidSaleRejection(super.message);
}
