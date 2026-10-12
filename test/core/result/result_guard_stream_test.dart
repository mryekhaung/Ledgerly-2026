import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/result/result_guard.dart';

/// Regression suite for [guardResultStream].
///
/// The original implementation declared `_ResultSink implements
/// EventSink<Result<T>>` and `add(Result<T> event)`. That type-checks — the
/// compiler unifies `eventTransformed`'s source and sink types — but it is
/// wrong: [Stream.eventTransformed] hands the sink the **raw** source events, so
/// the first `add` throws
///
/// ```
/// type 'X' is not a subtype of type 'Result<X>' of 'event'
/// ```
///
/// at runtime. Every streaming repository method funnels through here, so the
/// whole app's streams went straight to their error branch while the analyzer
/// and the compiler both stayed silent. These tests pin the untransformed type
/// at the seam.
void main() {
  group('guardResultStream on a successful stream', () {
    test('should_wrap_each_event_in_a_success', () async {
      final stream = guardResultStream<int>(
        Stream<int>.fromIterable(<int>[1, 2]),
      );

      final events = await stream.toList();

      expect(events, hasLength(2));
      expect(events[0], const Success<int>(1));
      expect(events[1], const Success<int>(2));
    });

    test('should_emit_the_success_value_unchanged', () async {
      final stream = guardResultStream<String>(Stream<String>.value('hello'));

      final events = await stream.toList();

      expect(events.single.valueOrNull, 'hello');
    });

    test('should_not_retype_the_event_as_a_result_downstream', () async {
      // The exact failure mode: a `List<int>` event reaching a sink typed
      // `Result<List<int>>`. Unwrapping here proves the sink takes the raw
      // element type, not the wrapped one.
      final stream = guardResultStream<List<int>>(
        Stream<List<int>>.value(const <int>[1, 2, 3]),
      );

      final events = await stream.toList();

      expect(events.single, isA<Success<List<int>>>());
      expect(events.single.valueOrNull, const <int>[1, 2, 3]);
    });
  });

  group('guardResultStream on a failing stream', () {
    test('should_map_an_error_event_to_an_err_without_closing', () async {
      final controller = StreamController<int>();
      addTearDown(controller.close);

      final stream = guardResultStream<int>(controller.stream);
      final received = <Result<int>>[];
      final subscription = stream.listen(received.add);

      controller
        ..add(1)
        ..addError(StateError('boom'))
        ..add(2);

      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(3));
      expect(received[0], const Success<int>(1));
      expect(received[1].isErr, isTrue);
      expect(received[1].failureOrNull, isA<StorageFailure>());
      expect(
        received[2],
        const Success<int>(2),
        reason: 'a transient error must not end the stream',
      );

      await subscription.cancel();
    });

    test('should_keep_the_cause_of_the_mapped_failure', () async {
      final controller = StreamController<int>();
      addTearDown(controller.close);

      final stream = guardResultStream<int>(controller.stream);
      final received = <Result<int>>[];
      final subscription = stream.listen(received.add);

      final cause = StateError('root cause');
      controller.addError(cause);

      await Future<void>.delayed(Duration.zero);

      expect(received.single.failureOrNull?.cause, same(cause));

      await subscription.cancel();
    });
  });

  group('guardResultStream closes with its source', () {
    test('should_complete_when_the_source_completes', () async {
      final stream = guardResultStream<int>(Stream<int>.value(7));

      await expectLater(stream, emitsInOrder(<Object>[const Success<int>(7)]));
    });
  });
}
