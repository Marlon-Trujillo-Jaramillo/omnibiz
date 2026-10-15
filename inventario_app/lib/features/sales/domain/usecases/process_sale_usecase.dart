import 'package:inventario_app/core/error/failures.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/core/utils/app_result.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/domain/repositories/sale_repository.dart';

/// Checkout: valida la venta y la confirma de forma atómica vía
/// [SaleRepository.commitSale] (stock + deuda + venta en una sola transacción).
class ProcessSaleUseCase {
  const ProcessSaleUseCase({required this.saleRepository});

  final SaleRepository saleRepository;

  static const _tag = 'ProcessSaleUC';

  Future<AppResult<SaleEntity>> execute(SaleEntity sale) async {
    AppLogger.i(_tag,
        'execute() total=${sale.totalAmount} method=${sale.paymentMethod} items=${sale.items.length}');

    final invalid = _validate(sale);
    if (invalid != null) {
      AppLogger.w(_tag, '  ✗ venta inválida: ${invalid.message}');
      return AppFailure(invalid);
    }

    try {
      final saved = await saleRepository.commitSale(_normalize(sale));
      AppLogger.i(_tag, 'execute() → venta id=${saved.id} guardada ✓');
      return AppSuccess(saved);
    } on SaleRejection catch (e) {
      AppLogger.w(_tag, '  ✗ venta rechazada: ${e.message}');
      return AppFailure(switch (e) {
        InsufficientStockRejection() => StockFailure(e.message),
        ProductNotFoundRejection()   => NotFoundFailure(e.message),
        InvalidSaleRejection()       => ValidationFailure(e.message),
      });
    } catch (e, st) {
      AppLogger.e(_tag, 'execute() → excepción inesperada', e, st);
      return AppFailure(DatabaseFailure(e.toString()));
    }
  }

  ValidationFailure? _validate(SaleEntity sale) {
    if (sale.storeId <= 0) {
      return const ValidationFailure('No hay una sucursal seleccionada');
    }
    if (sale.items.isEmpty) {
      return const ValidationFailure('El carrito está vacío');
    }
    if (sale.items.any((i) => i.quantity <= 0 || i.unitPrice < 0)) {
      return const ValidationFailure('Hay productos con cantidad o precio inválido');
    }
    if (sale.paymentMethod == PaymentMethods.credit && sale.customerId == null) {
      return const ValidationFailure('Para vender fiado selecciona un cliente');
    }
    return null;
  }

  /// Recalcula los totales a partir de las líneas: no se confía en el total
  /// que manda la UI.
  SaleEntity _normalize(SaleEntity sale) {
    final items = [
      for (final i in sale.items)
        SaleItemEntity(
          productId:        i.productId,
          productName:      i.productName,
          quantity:         i.quantity,
          unitPrice:        i.unitPrice,
          totalPrice:       i.unitPrice * i.quantity,
          selectedVariants: i.selectedVariants,
        ),
    ];
    final subtotal = items.fold(0, (sum, i) => sum + i.totalPrice);
    return sale.copyWith(
      items:       items,
      totalAmount: subtotal + sale.taxAmount - sale.discountAmount,
    );
  }
}
