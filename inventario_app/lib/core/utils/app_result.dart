import 'package:inventario_app/core/error/failures.dart';

/// Result type limpio para operaciones que pueden fallar.
///
/// Reemplaza el patrón de tuplas `({T value, Failure? failure})`.
///
/// Uso:
/// ```dart
/// final result = await useCase.execute(data);
/// result.when(
///   onSuccess: (value) => ...,
///   onFailure: (failure) => ...,
/// );
/// ```
sealed class AppResult<T> {
  const AppResult();
}

final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.data);
  final T data;
}

final class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.failure);
  final Failure failure;
}

extension AppResultX<T> on AppResult<T> {
  bool get isSuccess => this is AppSuccess<T>;
  bool get isFailure => this is AppFailure<T>;

  T? get dataOrNull => switch (this) {
        AppSuccess(:final data) => data,
        AppFailure()            => null,
      };

  Failure? get failureOrNull => switch (this) {
        AppSuccess()             => null,
        AppFailure(:final failure) => failure,
      };

  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        AppSuccess(:final data)    => onSuccess(data),
        AppFailure(:final failure) => onFailure(failure),
      };
}
