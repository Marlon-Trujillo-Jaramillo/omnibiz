import 'failures.dart';

abstract final class ErrorMapper {
  static String toMessage(Failure failure) => switch (failure) {
        DatabaseFailure() =>
          'Error al acceder a los datos. Intenta de nuevo.',
        ValidationFailure(:final message) => message,
        NotFoundFailure() =>
          'El registro no fue encontrado.',
        NetworkFailure() =>
          'Sin conexión. Verifica tu red e intenta de nuevo.',
        UnauthorizedFailure() =>
          'No tienes permiso para realizar esta acción.',
        StockFailure(:final message) => message,
        UnexpectedFailure() =>
          'Ocurrió un error inesperado. Intenta de nuevo.',
      };
}
