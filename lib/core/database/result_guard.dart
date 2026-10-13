import 'dart:async';

import 'package:drift/drift.dart'
    show DriftWrappedException, InvalidDataException;
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';

/// Translates an exception thrown by the local database into a [Failure].
///
/// Lives in `core/database/` — **not** `core/result/` — because it is the one
/// place that knows about Drift's exception types, and `core/result/` must stay
/// pure Dart (it is imported by `domain`; `docs/Agent.md` §3.1, enforced by
/// `test/core/layer_rule_test.dart`). `GuardResult` is a data-layer concern:
/// `docs/Agent.md` §3.4 puts exception→`Failure` mapping in `data/`, and this is
/// the shared implementation every drift-backed repository reuses.
///
/// The rule: **an exception never crosses out of `data/`.** Repositories wrap
/// their bodies in [guardResult] and return the [Failure] it produces.
///
/// Note there is no `DriftException` in drift 2.32 — the engine's own errors
/// reach us as `SqliteException` (from `package:sqlite3`, which drift
/// re-exports nothing of), so constraint detection has to read the message
/// text. The three drift-specific wrappers are matched by type first.
abstract final class FailureMapper {
  const FailureMapper._();

  /// Maps [error] to the most specific storage [Failure] it warrants.
  static StorageFailure fromStorage(Object error, [StackTrace? stackTrace]) {
    if (error is InvalidDataException) {
      // Drift's own type-verification failure: a column was given a value that
      // violates a declared constraint. That is a bug in the caller, so it is
      // kept distinct from a disk error.
      return StorageFailure(
        'Invalid data for column',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is DriftWrappedException) {
      // Drift's annotated wrapper around an engine error — unwrap the cause so
      // the classification below sees the real SQLite code.
      return _fromEngine(error.cause ?? error, error.trace ?? stackTrace);
    }

    return _fromEngine(error, stackTrace);
  }

  /// Classifies a raw engine error (a `SqliteException`) by its message.
  ///
  /// `package:sqlite3`'s exception is not a dependency of this layer, so it is
  /// matched structurally rather than by type. The message check is deliberately
  /// loose: a missed match degrades to a generic storage failure, which is a
  /// worse message but not a wrong one.
  static StorageFailure _fromEngine(Object error, StackTrace? stackTrace) {
    final message = error.toString().toLowerCase();
    if (message.contains('unique') || message.contains('constraint')) {
      return StorageFailure(
        'Storage constraint violated',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (message.contains('readonly') || message.contains('read-only')) {
      return StorageFailure(
        'Storage is read-only',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return StorageFailure(
      'Storage error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

/// Runs [body], converting any thrown [Object] into an [Err] with a mapped
/// [Failure].
///
/// The single seam where `data/` exceptions stop. Callers get a `Result<T>` back
/// and the presentation layer never needs a `try` (`docs/Agent.md` §3.4).
///
/// Catches `Object`, not `Exception`: a `StateError` is an `Error`, a platform
/// channel failure can be either, and both must be mapped rather than crashing a
/// notifier.
Future<Result<T>> guardResult<T>(
  Future<T> Function() body, {
  Failure Function(Object error, StackTrace stackTrace)? onError,
}) async {
  try {
    return Success(await body());
  } on Object catch (error, stackTrace) {
    return Err<T>(
      onError?.call(error, stackTrace) ??
          FailureMapper.fromStorage(error, stackTrace),
    );
  }
}

/// The streaming counterpart of [guardResult].
///
/// Emits each event as a `Success` and converts an error event into an `Err`
/// **without closing the stream** — a Drift stream can fail transiently, and a
/// `StreamNotifier` should render an error state and still receive the next
/// update rather than going permanently dead.
///
/// Implemented with [Stream.eventTransformed] rather than `async*` + `await for`
/// because a `for` loop rethrows an upstream error into the generator, ending
/// the stream — the exact behaviour being avoided. A transformer sink can accept
/// the error and keep going.
Stream<Result<T>> guardResultStream<T>(Stream<T> source) =>
    Stream<Result<T>>.eventTransformed(source, _ResultSink<T>.new);

/// Maps a raw event stream to a `Result` stream, converting errors to `Err`
/// values instead of terminating.
///
/// **Why `add` takes `T`, not `Result<T>`:** [Stream.eventTransformed] hands the
/// sink the *source* events. Its signature is
/// `Stream<R> eventTransformed<S, R>(Stream<S>, EventSink<R> Function())` — but
/// `_ResultSink` is both the `S` consumer and the `R` producer, so the sink's
/// `add` is called with the **raw** `T` and must do the wrapping itself.
/// Declaring `add(Result<T>)` type-checks at the call site (the compiler unifies
/// `S` and `R` to `Result<T>`) and then fails at runtime with
/// `type 'T' is not a subtype of type 'Result<T>' of 'event'` on the first event.
class _ResultSink<T> implements EventSink<T> {
  _ResultSink(this._downstream);

  final EventSink<Result<T>> _downstream;

  @override
  void add(T event) => _downstream.add(Success<T>(event));

  @override
  void addError(Object error, [StackTrace? stackTrace]) => _downstream.add(
    Err<T>(FailureMapper.fromStorage(error, stackTrace ?? StackTrace.empty)),
  );

  @override
  void close() => _downstream.close();
}
