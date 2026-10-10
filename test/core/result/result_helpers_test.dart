import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';

/// `Result` is the error channel for every repository and use case, so its
/// helpers must be exhaustively correct — a short-circuit that accidentally
/// runs on the `Err` branch would silently swallow a failure.
void main() {
  const failure = StorageFailure('disk full');
  const result = Err<int>(failure);
  const success = Success<int>(42);

  group('Result.isSuccess / isErr', () {
    test('should_report_success_when_holding_a_value', () {
      expect(success.isSuccess, isTrue);
      expect(success.isErr, isFalse);
    });

    test('should_report_err_when_holding_a_failure', () {
      expect(result.isSuccess, isFalse);
      expect(result.isErr, isTrue);
    });
  });

  group('Result.valueOrNull / failureOrNull', () {
    test('should_expose_value_when_successful', () {
      expect(success.valueOrNull, 42);
      expect(success.failureOrNull, isNull);
    });

    test('should_expose_failure_when_failed', () {
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
    });

    test('should_not_conflate_a_null_value_with_a_failure', () {
      // A successful null is a legitimate outcome for a lookup; it must not be
      // mistaken for an error.
      const nullSuccess = Success<int?>(null);

      expect(nullSuccess.isSuccess, isTrue);
      expect(nullSuccess.failureOrNull, isNull);
    });
  });

  group('Result.getOrNull', () {
    test('should_return_the_value_when_successful', () {
      expect(success.getOrNull, 42);
    });

    test('should_return_null_when_failed', () {
      expect(result.getOrNull, isNull);
    });

    test('should_match_valueOrNull_when_compared', () {
      expect(success.getOrNull, success.valueOrNull);
      expect(result.getOrNull, result.valueOrNull);
    });
  });

  group('Result.getOrElse', () {
    test('should_return_the_value_when_successful', () {
      expect(success.getOrElse(0), 42);
    });

    test('should_return_the_fallback_when_failed', () {
      expect(result.getOrElse(0), 0);
    });
  });

  group('Result.getOrElseLazy', () {
    test('should_return_the_value_without_calling_onErr_when_successful', () {
      var called = false;
      final value = success.getOrElseLazy((_) {
        called = true;
        return 0;
      });

      expect(value, 42);
      expect(
        called,
        isFalse,
        reason: 'onErr must not run on the Success branch',
      );
    });

    test('should_call_onErr_with_the_failure_when_failed', () {
      late Failure received;
      final value = result.getOrElseLazy((f) {
        received = f;
        return -1;
      });

      expect(value, -1);
      expect(received, failure);
    });
  });

  group('Result.fold', () {
    test('should_call_onSuccess_when_successful', () {
      final output = success.fold(
        onSuccess: (v) => 'got $v',
        onErr: (f) => 'failed',
      );

      expect(output, 'got 42');
    });

    test('should_call_onErr_when_failed', () {
      final output = result.fold(
        onSuccess: (v) => 'got $v',
        onErr: (f) => 'failed',
      );

      expect(output, 'failed');
    });

    test('should_not_invoke_the_other_branch_when_folding', () {
      var errCalled = false;
      success.fold(
        onSuccess: (_) => 0,
        onErr: (_) {
          errCalled = true;
          return 1;
        },
      );
      expect(errCalled, isFalse);
    });
  });

  group('Result.map', () {
    test('should_transform_the_value_when_successful', () {
      expect(success.map((v) => v * 2).valueOrNull, 84);
    });

    test('should_leave_the_failure_untouched_when_failed', () {
      final mapped = result.map((v) => v * 2);

      expect(mapped.isErr, isTrue);
      expect(mapped.failureOrNull, failure);
    });

    test('should_allow_changing_the_value_type_when_successful', () {
      expect(success.map((v) => v.toString()).valueOrNull, '42');
    });

    test('should_not_invoke_the_transform_when_failed', () {
      var called = false;
      result.map((v) {
        called = true;
        return v;
      });
      expect(called, isFalse);
    });
  });

  group('Result.flatMap', () {
    test('should_chain_when_the_first_result_is_successful', () {
      final chained = success.flatMap((v) => Success<int>(v + 1));

      expect(chained.valueOrNull, 43);
    });

    test('should_short_circuit_when_the_first_result_is_failed', () {
      var called = false;
      final chained = result.flatMap((v) {
        called = true;
        return Success<int>(v);
      });

      expect(called, isFalse, reason: 'transform must not run after an Err');
      expect(chained.failureOrNull, failure);
    });

    test('should_propagate_a_failure_produced_by_the_transform', () {
      const downstream = NetworkFailure('timeout');
      final chained = success.flatMap((_) => const Err<String>(downstream));

      expect(chained.isErr, isTrue);
      expect(chained.failureOrNull, downstream);
    });

    test('should_change_the_value_type_when_chaining', () {
      final chained = success.flatMap((v) => Success<String>('$v!'));

      expect(chained.valueOrNull, '42!');
    });
  });

  group('Result.mapErr', () {
    test('should_transform_the_failure_when_failed', () {
      final mapped = result.mapErr(
        (f) => ConflictFailure('retry: ${f.message}'),
      );

      expect(mapped.failureOrNull, isA<ConflictFailure>());
      expect(mapped.failureOrNull?.message, contains('disk full'));
    });

    test('should_leave_a_success_untouched_when_successful', () {
      var called = false;
      final mapped = success.mapErr((f) {
        called = true;
        return f;
      });

      expect(called, isFalse);
      expect(mapped.valueOrNull, 42);
    });
  });

  group('Result.onSuccess / onErr', () {
    test('should_run_the_effect_when_successful', () {
      var seen = 0;
      success.onSuccess((v) => seen = v);

      expect(seen, 42);
    });

    test('should_not_run_the_success_effect_when_failed', () {
      var called = false;
      result.onSuccess((_) => called = true);

      expect(called, isFalse);
    });

    test('should_run_the_error_effect_when_failed', () {
      Failure? seen;
      result.onErr((f) => seen = f);

      expect(seen, failure);
    });

    test('should_not_run_the_error_effect_when_successful', () {
      var called = false;
      success.onErr((_) => called = true);

      expect(called, isFalse);
    });

    test('should_return_the_same_result_when_chaining_effects', () {
      var successRan = false;
      var errRan = false;
      final chained = success
          .onSuccess((_) => successRan = true)
          .onErr((_) => errRan = true);

      expect(chained.valueOrNull, 42);
      expect(successRan, isTrue);
      expect(errRan, isFalse);
    });
  });

  group('Result.toRecord', () {
    test('should_expose_the_value_and_null_failure_when_successful', () {
      final (value, err) = success.toRecord();

      expect(value, 42);
      expect(err, isNull);
    });

    test('should_expose_null_and_the_failure_when_failed', () {
      final (value, err) = result.toRecord();

      expect(value, isNull);
      expect(err, failure);
    });
  });

  group('Result equality', () {
    test('should_be_equal_when_both_are_successes_with_the_same_value', () {
      expect(const Success<int>(1), const Success<int>(1));
      expect(const Success<int>(1).hashCode, const Success<int>(1).hashCode);
    });

    test('should_not_be_equal_when_success_values_differ', () {
      expect(const Success<int>(1), isNot(const Success<int>(2)));
    });

    test('should_be_equal_when_both_are_errs_with_the_same_failure', () {
      const a = Err<int>(StorageFailure('x'));
      const b = Err<int>(StorageFailure('x'));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('should_not_be_equal_when_failures_differ', () {
      expect(
        const Err<int>(StorageFailure('x')),
        isNot(const Err<int>(StorageFailure('y'))),
      );
    });
  });

  group('Result toString', () {
    test('should_describe_a_success_when_successful', () {
      expect(success.toString(), 'Success<int>(42)');
    });

    test('should_describe_an_err_when_failed', () {
      expect(result.toString(), contains('Err<int>'));
    });
  });

  group('Failure hierarchy', () {
    test('should_keep_the_message_when_constructed', () {
      expect(const ValidationFailure('bad input').message, 'bad input');
    });

    test('should_expose_field_errors_when_validation_fails', () {
      const validation = ValidationFailure(
        'invalid',
        fieldErrors: {'amount': 'must_be_positive'},
      );

      expect(validation.fieldErrors['amount'], 'must_be_positive');
    });

    test('should_default_field_errors_to_empty_when_not_provided', () {
      expect(const ValidationFailure('invalid').fieldErrors, isEmpty);
    });

    test('should_expose_status_code_when_network_fails', () {
      const network = NetworkFailure('server error', statusCode: 503);

      expect(network.statusCode, 503);
    });

    test('should_default_status_code_to_null_when_transport_fails', () {
      expect(const NetworkFailure('offline').statusCode, isNull);
    });

    test('should_flag_cancelled_when_auth_is_dismissed', () {
      expect(
        const AuthFailure('dismissed', isCancelled: true).isCancelled,
        isTrue,
      );
      expect(const AuthFailure('expired').isCancelled, isFalse);
    });

    test('should_expose_row_number_when_parsing_fails', () {
      expect(const ParseFailure('bad row', rowNumber: 7).rowNumber, 7);
    });

    test('should_retain_cause_when_provided', () {
      final cause = Exception('root');
      final failure = StorageFailure('wrapped', cause: cause);

      expect(failure.cause, cause);
    });

    test('should_retain_stack_trace_when_provided', () {
      final trace = StackTrace.current;
      final failure = UnexpectedFailure('boom', stackTrace: trace);

      expect(failure.stackTrace, trace);
    });

    test('should_be_exhaustive_when_switched_over', () {
      // Compile-time guarantee: if a new Failure subtype is added, this switch
      // stops compiling, which is the point of keeping the hierarchy sealed.
      String describe(Failure f) => switch (f) {
        StorageFailure() => 'storage',
        NetworkFailure() => 'network',
        AuthFailure() => 'auth',
        ValidationFailure() => 'validation',
        NotFoundFailure() => 'notFound',
        ConflictFailure() => 'conflict',
        ParseFailure() => 'parse',
        UnexpectedFailure() => 'unexpected',
      };

      expect(describe(const StorageFailure('x')), 'storage');
      expect(describe(const NetworkFailure('x')), 'network');
      expect(describe(const AuthFailure('x')), 'auth');
      expect(describe(const ValidationFailure('x')), 'validation');
      expect(describe(const NotFoundFailure('x')), 'notFound');
      expect(describe(const ConflictFailure('x')), 'conflict');
      expect(describe(const ParseFailure('x')), 'parse');
      expect(describe(const UnexpectedFailure('x')), 'unexpected');
    });

    test('should_include_the_type_and_message_when_described', () {
      expect(
        const StorageFailure('disk full').toString(),
        'StorageFailure(disk full)',
      );
    });
  });
}
