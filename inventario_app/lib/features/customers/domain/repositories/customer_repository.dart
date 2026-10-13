import '../entities/customer_entity.dart';

abstract interface class CustomerRepository {
  Future<List<CustomerEntity>> getAll({required int storeId});
  Future<CustomerEntity?> getById(int id);
  Future<void> save(CustomerEntity customer);
  Future<void> delete(int id);

  /// Abono a la deuda ([amount] en centavos), validado dentro de la
  /// transacción contra la deuda actual. Lanza [InvalidPaymentException] si
  /// es <= 0 o mayor que la deuda.
  Future<void> registerPayment(int id, int amount);
}

class InvalidPaymentException implements Exception {
  const InvalidPaymentException(this.message);
  final String message;

  @override
  String toString() => 'InvalidPaymentException: $message';
}
