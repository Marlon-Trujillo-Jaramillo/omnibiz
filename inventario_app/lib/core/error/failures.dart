sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Error de base de datos']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Registro no encontrado']);
}

final class StockFailure extends Failure {
  const StockFailure(super.message);
}
