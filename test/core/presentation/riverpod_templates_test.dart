import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/presentation/riverpod_templates.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';

class _TestStreamNotifier extends TemplateStreamNotifier<int> {
  _TestStreamNotifier(this._stream);

  final Stream<int> _stream;

  @override
  Stream<int> build() => _stream;
}

void main() {
  group('TemplateCounterNotifier', () {
    test('should_start_at_zero_and_support_increment_and_reset', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider =
          NotifierProvider.autoDispose<TemplateCounterNotifier, int>(
            TemplateCounterNotifier.new,
          );

      expect(container.read(provider), 0);

      container.read(provider.notifier).increment();
      expect(container.read(provider), 1);

      container.read(provider.notifier).increment();
      expect(container.read(provider), 2);

      container.read(provider.notifier).reset();
      expect(container.read(provider), 0);
    });
  });

  group('TemplateAsyncNotifier', () {
    test('should_load_successfully_when_initial_fetch_succeeds', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider =
          AsyncNotifierProvider.autoDispose<
            TemplateAsyncNotifier<String>,
            String
          >(
            () => TemplateAsyncNotifier<String>(
              fetchInitial: () async => const Success('initial-value'),
              mutateAction: (cur, delta) async => Success('$cur-$delta'),
            ),
          );

      final result = await container.read(provider.future);
      expect(result, 'initial-value');

      final mutated = await container.read(provider.notifier).mutate('updated');
      expect(mutated, isTrue);
      expect(container.read(provider).value, 'initial-value-updated');
    });

    test('should_fail_when_initial_fetch_returns_error', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const testFailure = UnexpectedFailure('fetch failed');
      final provider =
          AsyncNotifierProvider.autoDispose<
            TemplateAsyncNotifier<String>,
            String
          >(
            () => TemplateAsyncNotifier<String>(
              fetchInitial: () async => const Err(testFailure),
              mutateAction: (cur, delta) async => Success('$cur-$delta'),
            ),
          );

      expect(
        container.read(provider.future),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('should_transition_to_error_when_mutation_fails', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const testFailure = ValidationFailure(
        'invalid field',
        fieldErrors: {'field': 'invalid'},
      );
      final provider =
          AsyncNotifierProvider.autoDispose<
            TemplateAsyncNotifier<String>,
            String
          >(
            () => TemplateAsyncNotifier<String>(
              fetchInitial: () async => const Success('initial'),
              mutateAction: (cur, delta) async => const Err(testFailure),
            ),
          );

      await container.read(provider.future);

      final mutated = await container.read(provider.notifier).mutate('fail');
      expect(mutated, isFalse);
      expect(container.read(provider).hasError, isTrue);
      expect(container.read(provider).error, equals(testFailure));
    });
  });

  group('TemplateStreamNotifier', () {
    test('should_emit_stream_events_and_handle_refresh', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = StreamController<int>.broadcast();
      addTearDown(controller.close);

      final provider =
          StreamNotifierProvider.autoDispose<_TestStreamNotifier, int>(
            () => _TestStreamNotifier(controller.stream),
          );

      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      controller.add(42);
      await pumpEventQueue();

      expect(container.read(provider).value, 42);

      // Verify refresh invalidates
      container.read(provider.notifier).refresh();
      expect(container.read(provider).isLoading, isTrue);

      controller.add(100);
      await pumpEventQueue();
      expect(container.read(provider).value, 100);
    });
  });

  group('createUseCaseBridge', () {
    test('should_provide_resolved_instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final bridge = createUseCaseBridge<String>(() => 'use-case-instance');
      expect(container.read(bridge), 'use-case-instance');
    });
  });
}
