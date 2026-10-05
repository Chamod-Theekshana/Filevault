import 'package:filevault/core/errors/failure.dart';

/// Lightweight result type so repositories never leak exceptions.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final T value) => value,
        Err<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Err<T>(:final Failure failure) => failure,
      };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final T value) => onSuccess(value),
      Err<T>(:final Failure failure) => onFailure(failure),
    };
  }

  /// Runs [body] and wraps thrown errors into an [Err].
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Success<T>(await body());
    } catch (error) {
      return Err<T>(Failure.fromException(error));
    }
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
