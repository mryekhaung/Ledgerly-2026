import 'package:ledgerly/core/result/result.dart';

/// Marker for operations that take no parameters.
///
/// Usage: `class WatchAll implements StreamUseCase<List<X>, NoParams>`.
final class NoParams {
  const NoParams();

  @override
  bool operator ==(Object other) => other is NoParams;

  @override
  int get hashCode => (NoParams).hashCode;
}

/// A single, async, fallible operation.
///
/// Parameters are a dedicated type per use case (`AddTransactionParams`), never
/// positional scalars — that keeps call sites readable and lets params grow
/// without breaking every caller (docs/Conventions.md §1).
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// A reactive operation returning a stream of results.
///
/// Used for Drift `watch*` queries (docs/Architecture.md §7): the stream emits a
/// new [Result] whenever the underlying data changes.
abstract interface class StreamUseCase<T, P> {
  Stream<Result<T>> call(P params);
}
