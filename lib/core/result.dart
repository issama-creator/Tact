/// Lightweight success/failure type for action results.
library;

sealed class Result<T, E> {
  const Result();

  const factory Result.ok(T value) = Ok<T, E>;
  const factory Result.err(E error) = Err<T, E>;

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  E? get errorOrNull => switch (this) {
        Ok() => null,
        Err(:final error) => error,
      };
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;
}

enum ActionError {
  noConnection,
  invalidRange,
  emptyReplacement,
  passwordBlocked,
  undoEmpty,
  failed,
}
