import 'package:ledgerly/core/result/failure.dart';

/// The result of any operation that can fail.
///
/// Repositories and use cases return `Result<T>`; the presentation layer never
/// catches exceptions (docs/Agent.md §3.4, docs/Architecture.md §8).
///
/// Sealed + exhaustive, so a `switch` over a [Result] is compile-checked.
sealed class Result<T> {
  const Result();

  /// True when this holds a value.
  bool get isSuccess => this is Success<T>;

  /// True when this holds a [Failure].
  bool get isErr => this is Err<T>;

  /// The value, or null when this is an [Err].
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The value, or null when this is an [Err].
  ///
  /// Alias of [valueOrNull] for call sites that read more naturally with a
  /// "maybe get" name (e.g. `result.getOrNull ?? fallback`).
  T? get getOrNull => valueOrNull;

  /// The value, or [fallback] when this is an [Err].
  ///
  /// Unlike [getOrNull] this hides the absence of a value behind a definite
  /// result — use it only when a sensible default genuinely exists.
  T getOrElse(T fallback) => valueOrNull ?? fallback;

  /// The value, or the result of [onErr] when this is an [Err].
  ///
  /// [onErr] receives the [Failure] so callers can decide a default based on
  /// *why* the operation failed.
  T getOrElseLazy(T Function(Failure failure) onErr) => switch (this) {
    Success<T>(:final value) => value,
    Err<T>(:final failure) => onErr(failure),
  };

  /// The failure, or null when this is a [Success].
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// Collapses both branches into a single value.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onErr,
  }) => switch (this) {
    Success<T>(:final value) => onSuccess(value),
    Err<T>(:final failure) => onErr(failure),
  };

  /// Chains another fallible operation, short-circuiting on [Err].
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Success<T>(:final value) => transform(value),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// Transforms the success value, leaving [Err] untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final value) => Success<R>(transform(value)),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// Transforms the failure, leaving [Success] untouched.
  ///
  /// The data layer uses this to enrich a low-level failure (e.g. attach a
  /// status code) without disturbing a successful value. The return type stays
  /// `Result<T>` because only the error channel changes.
  Result<T> mapErr(Failure Function(Failure failure) transform) =>
      switch (this) {
        Success<T>() => this,
        Err<T>(:final failure) => Err<T>(transform(failure)),
      };

  /// Runs [effect] for its side effect when this is a [Success], then returns
  /// `this` unchanged so it can be chained.
  ///
  /// The effect must return void — this is a hook for logging, not a transform.
  Result<T> onSuccess(void Function(T value) effect) {
    if (this case Success<T>(:final value)) effect(value);
    return this;
  }

  /// Runs [effect] for its side effect when this is an [Err], then returns
  /// `this` unchanged so it can be chained.
  Result<T> onErr(void Function(Failure failure) effect) {
    if (this case Err<T>(:final failure)) effect(failure);
    return this;
  }

  /// Converts to a Dart record, convenient for destructuring at call sites.
  (T?, Failure?) toRecord() => (valueOrNull, failureOrNull);
}

/// A successful operation holding [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Success<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Success<T>, value);

  @override
  String toString() => 'Success<$T>($value)';
}

/// A failed operation holding [failure]. Named `Err` to avoid colliding with
/// the built-in [Error].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err<T>, failure);

  @override
  String toString() => 'Err<$T>($failure)';
}
