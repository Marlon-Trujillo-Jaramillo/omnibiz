import 'package:inventario_app/core/error/failures.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/core/utils/app_result.dart';
import 'package:inventario_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:inventario_app/features/inventory/domain/repositories/product_repository.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';
import 'package:inventario_app/features/sales/domain/repositories/sale_repository.dart';

class ProcessSaleUseCase {
  const ProcessSaleUseCase({
    required this.saleRepository,
    required this.productRepository,
    required this.customerRepository,
  });

  final SaleRepository saleRepository;
  final ProductRepository productRepository;
  final CustomerRepository customerRepository;

  static const _tag = 'ProcessSaleUC';

  Future<AppResult<SaleEntity>> execute(SaleEntity sale) async {
    AppLogger.i(_tag,
        'execute() total=${sale.totalAmount} method=${sale.paymentMethod} items=${sale.items.length}');
    try {
      for (final item in sale.items) {
        AppLogger.d(_tag,
            '  → validando stock: "${item.productName}" (id=${item.productId}) qty=${item.quantity}');
        final product = await productRepository.getById(item.productId);
        if (product == null) {
          AppLogger.w(_tag, '  ✗ producto no encontrado id=${item.productId}');
          return AppFailure(
            NotFoundFailure('Producto "${item.productName}" no encontrado'),
          );
        }
        if (product.stock < item.quantity) {
          AppLogger.w(_tag,
              '  ✗ stock insuficiente: disponible=${product.stock} solicitado=${item.quantity}');
          return AppFailure(
            StockFailure(
              'Stock insuficiente para "${item.productName}". '
              'Disponible: ${product.stock}, solicitado: ${item.quantity}',
            ),
          );
        }
        final newStock = product.stock - item.quantity;
        AppLogger.d(_tag, '  ✓ stock ok, descontando → $newStock');
        await productRepository.updateStock(item.productId, newStock);
      }

      if (sale.paymentMethod == 'Fiado' && sale.customerId != null) {
        AppLogger.i(_tag,
            'Fiado: sumando ${sale.totalAmount} a cliente id=${sale.customerId}');
        await customerRepository.updateDebt(sale.customerId!, sale.totalAmount);
      }

      await saleRepository.save(sale);
      AppLogger.i(_tag, 'execute() → venta guardada correctamente ✓');
      return AppSuccess(sale);
    } catch (e, st) {
      AppLogger.e(_tag, 'execute() → excepción inesperada', e, st);
      return AppFailure(DatabaseFailure(e.toString()));
    }
  }
}
