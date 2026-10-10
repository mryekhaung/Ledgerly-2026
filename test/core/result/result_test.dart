import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';

void main() {
  group('Success', () {
    test('should_report_success_state_when_holding_a_value', () {
      const result = Success<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isErr, isFalse);
      expect(result.value, 42);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('should_be_equal_when_values_are_equal', () {
      expect(const Success<int>(42), const Success<int>(42));
      expect(const Success<int>(42), isNot(const Success<int>(43)));
      expect(const Success<int>(42).hashCode, const Success<int>(42).hashCode);
    });
  });

  group('Err', () {
    test('should_report_error_state_when_holding_a_failure', () {
      const failure = StorageFailure('db closed');
      const result = Err<int>(failure);

      expect(result.isErr, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.failure, failure);
      expect(result.failureOrNull, failure);
      expect(result.valueOrNull, isNull);
    });

    test('should_store_cause_and_stack_trace_when_provided', () {
      final cause = StateError('boom');
      final trace = StackTrace.current;
      final failure = UnexpectedFailure('oops', cause: cause, stackTrace: trace);

      expect(failure.cause, cause);
      expect(failure.stackTrace, trace);
      expect(failure.message, 'oops');
    });
  });

  group('fold', () {
    test('should_call_on_success_when_successful', () {
      const result = Success<int>(5);

      final folded = result.fold(
        onSuccess: (value) => 'value=$value',
        onErr: (failure) => 'failed',
      );

      expect(folded, 'value=5');
    });

    test('should_call_on_err_when_failed', () {
      const result = Err<int>(NotFoundFailure('gone'));

      final folded = result.fold(
        onSuccess: (value) => 'value=$value',
        onErr: (failure) => 'failed:${failure.message}',
      );

      expect(folded, 'failed:gone');
    });
  });

  group('map', () {
    test('should_transform_value_when_successful', () {
      const result = Success<int>(5);

      final mapped = result.map((value) => value * 2);

      expect(mapped, const Success<int>(10));
    });

    test('should_preserve_failure_when_not_successful', () {
      const failure = NetworkFailure('offline', statusCode: 503);
      const result = Err<int>(failure);

      final mapped = result.map((value) => value * 2);

      expect(mapped.isErr, isTrue);
      expect(mapped.failureOrNull, same(failure));
    });
  });

  group('flatMap', () {
    test('should_chain_when_first_succeeds', () {
      const result = Success<int>(5);

      final chained = result.flatMap((value) => Success<String>('v$value'));

      expect(chained, const Success<String>('v5'));
    });

    test('should_short_circuit_when_first_fails', () {
      const failure = ConflictFailure('duplicate');
      const result = Err<int>(failure);
      var transformCalled = false;

      final chained = result.flatMap((value) {
        transformCalled = true;
        return const Success<String>('never');
      });

      expect(transformCalled, isFalse);
      expect(chained.failureOrNull, same(failure));
    });

    test('should_propagate_failure_from_transform_when_second_fails', () {
      const result = Success<int>(5);

      final chained = result.flatMap(
        (value) => const Err<String>(ValidationFailure('bad amount')),
      );

      expect(chained.isErr, isTrue);
      expect(chained.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('toRecord', () {
    test('should_expose_value_and_null_when_successful', () {
      final (value, failure) = const Success<int>(7).toRecord();

      expect(value, 7);
      expect(failure, isNull);
    });

    test('should_expose_null_and_failure_when_failed', () {
      final (value, failure) = const Err<int>(ParseFailure('bad row')).toRecord();

      expect(value, isNull);
      expect(failure, isA<ParseFailure>());
    });
  });

  group('Failure hierarchy', () {
    test('should_be_exhaustive_when_switched_over', () {
      // A switch over the sealed hierarchy compiles only because every case is
      // covered - this test guards the contract documented in failure.dart.
      String describe(Failure failure) => switch (failure) {
        StorageFailure() => 'storage',
        NetworkFailure() => 'network',
        AuthFailure() => 'auth',
        ValidationFailure() => 'validation',
        NotFoundFailure() => 'not-found',
        ConflictFailure() => 'conflict',
        ParseFailure() => 'parse',
        UnexpectedFailure() => 'unexpected',
      };

      expect(describe(const StorageFailure('x')), 'storage');
      expect(describe(const NetworkFailure('x')), 'network');
      expect(describe(const AuthFailure('x')), 'auth');
      expect(describe(const ValidationFailure('x')), 'validation');
      expect(describe(const NotFoundFailure('x')), 'not-found');
      expect(describe(const ConflictFailure('x')), 'conflict');
      expect(describe(const ParseFailure('x')), 'parse');
      expect(describe(const UnexpectedFailure('x')), 'unexpected');
    });

    test('should_carry_status_code_when_network_failure', () {
      const failure = NetworkFailure('bad gateway', statusCode: 502);

      expect(failure.statusCode, 502);
    });

    test('should_flag_cancellation_when_auth_failure_is_dismissed', () {
      const cancelled = AuthFailure('dismissed', isCancelled: true);

      expect(cancelled.isCancelled, isTrue);
    });

    test('should_carry_field_errors_when_validation_failure', () {
      const failure = ValidationFailure(
        'invalid form',
        fieldErrors: {'amount': 'errors.amount.required'},
      );

      expect(failure.fieldErrors['amount'], 'errors.amount.required');
    });

    test('should_carry_row_number_when_parse_failure_from_import', () {
      const failure = ParseFailure('bad row', rowNumber: 42);

      expect(failure.rowNumber, 42);
    });

    test('should_default_field_errors_to_empty_map_when_not_provided', () {
      const failure = ValidationFailure('invalid form');

      expect(failure.fieldErrors, isEmpty);
    });
  });
}
