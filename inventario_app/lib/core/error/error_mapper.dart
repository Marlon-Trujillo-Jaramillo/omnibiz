import 'failures.dart';

abstract final class ErrorMapper {
  static String toMessage(Failure failure) => switch (failure) {
        DatabaseFailure() =>
          'Error al acceder a los datos. Intenta de nuevo.',
        ValidationFailure(:final message) => message,
        NotFoundFailure() =>
          'El registro no fue encontrado.',
        StockFailure(:final message) => message,
      };
}
