import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';

/// Contract tests for the use-case base types.
///
/// `NoParams` deserves particular attention: it is used as a generic type
/// argument, so its `==`/`hashCode` must be value-based or every `const`
/// NoParams() instance would be a distinct provider key.
void main() {
  group('NoParams', () {
    test('should_be_equal_when_two_instances_are_compared', () {
      expect(const NoParams(), const NoParams());
    });

    test('should_share_a_hash_code_when_two_instances_are_compared', () {
      expect(const NoParams().hashCode, const NoParams().hashCode);
    });

    test('should_not_equal_another_type_when_compared', () {
      expect(const NoParams() == Object(), isFalse);
    });
  });

  group('UseCase', () {
    test('should_return_a_result_when_called', () async {
      final useCase = _DoubleNumber();

      final result = await useCase(21);

      expect(result.valueOrNull, 42);
    });

    test('should_propagate_a_failure_when_the_operation_fails', () async {
      final useCase = _FailingUseCase();

      final result = await useCase(const NoParams());

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
      'should_be_usable_with_no_params_when_params_are_not_needed',
      () async {
        final useCase = _CountAll();

        final result = await useCase(const NoParams());

        expect(result.valueOrNull, 3);
      },
    );

    test('should_allow_chaining_use_cases_when_composed', () async {
      final result = await _DoubleNumber()(21);

      final chained = result.flatMap((v) => Success<int>(v + 1));

      expect(chained.valueOrNull, 43);
    });
  });

  group('StreamUseCase', () {
    test('should_emit_results_when_subscribed', () async {
      final useCase = _WatchNumbers();

      final emitted = await useCase(const NoParams()).toList();

      expect(emitted, hasLength(3));
      expect(emitted.map((r) => r.valueOrNull), [1, 2, 3]);
    });

    test('should_emit_an_err_when_the_stream_fails', () async {
      final useCase = _WatchWithFailure();

      final emitted = await useCase(const NoParams()).toList();

      expect(emitted, hasLength(2));
      expect(emitted.last.isErr, isTrue);
      expect(emitted.last.failureOrNull, isA<NetworkFailure>());
    });

    test('should_stop_emitting_when_the_stream_closes', () async {
      final useCase = _WatchNumbers();

      final emitted = await useCase(const NoParams()).toList();

      expect(emitted, hasLength(3));
    });
  });
}

/// Doubles its parameter. A minimal [UseCase] implementation.
final class _DoubleNumber implements UseCase<int, int> {
  @override
  Future<Result<int>> call(int params) async => Success<int>(params * 2);
}

/// Always fails, to prove the error channel flows through `call`.
final class _FailingUseCase implements UseCase<int, NoParams> {
  @override
  Future<Result<int>> call(NoParams params) async =>
      const Err<int>(NotFoundFailure('nothing here'));
}

/// Takes [NoParams] and succeeds — the common "get everything" shape.
final class _CountAll implements UseCase<int, NoParams> {
  @override
  Future<Result<int>> call(NoParams params) async => const Success<int>(3);
}

/// Emits three successful results then closes.
final class _WatchNumbers implements StreamUseCase<int, NoParams> {
  @override
  Stream<Result<int>> call(NoParams params) =>
      Stream.fromIterable(const [1, 2, 3]).map(Success<int>.new);
}

/// Emits one success then a failure, like a Drift watch hitting an error.
final class _WatchWithFailure implements StreamUseCase<int, NoParams> {
  @override
  Stream<Result<int>> call(NoParams params) async* {
    yield const Success<int>(1);
    yield const Err<int>(NetworkFailure('connection lost'));
  }
}
