import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';

/// Riverpod 3 Baseline Templates and Best Practices.
///
/// In accordance with `docs/Architecture.md` §5, `docs/Conventions.md` §1, and
/// `docs/Versions.md` §4:
/// 1. We exclusively use **Riverpod 3.x** primitives:
///    - [Notifier] for synchronous UI state (forms, filters, UI selections).
///    - [AsyncNotifier] for asynchronous load/mutation operations.
///    - [StreamNotifier] for reactive subscriptions (e.g., Drift watches).
/// 2. Legacy Riverpod providers (`StateProvider`, `StateNotifierProvider`,
///    `ChangeNotifierProvider`) from `package:flutter_riverpod/legacy.dart` are
///    **strictly forbidden** and blocked by CI and architectural tests.
/// 3. Providers are **auto-disposed by default** (`autoDispose`) to prevent
///    memory leaks. Global singletons (like settings) must deliberately use
///    `ref.keepAlive()` with documented reasons.
/// 4. Asynchronous mutations in notifiers must always guard post-await execution
///    with `if (!ref.mounted) return;`.
/// 5. Domain use cases are bridged into Riverpod via thin [Provider] wrappers
///    that resolve from `get_it`. Business logic belongs in domain use cases and
///    validators, never directly inside notifiers.

// ---------------------------------------------------------------------------
// 1. Synchronous UI State Template (Notifier)
// ---------------------------------------------------------------------------

/// Canonical template for a synchronous state notifier.
///
/// Use this pattern for:
/// - Form input buffers (e.g., keypad entries, filter toggles, active tab).
/// - Purely client-side UI states that do not require async fetching on mount.
///
/// Example usage:
/// ```dart
/// final counterProvider =
///     NotifierProvider.autoDispose<TemplateCounterNotifier, int>(
///       TemplateCounterNotifier.new,
///     );
/// ```
class TemplateCounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Increments the counter state.
  void increment() => state = state + 1;

  /// Resets the counter state to zero.
  void reset() => state = 0;
}

// ---------------------------------------------------------------------------
// 2. Asynchronous State Template (AsyncNotifier)
// ---------------------------------------------------------------------------

/// Canonical template for an asynchronous state notifier.
///
/// Use this pattern for:
/// - Asynchronously loaded resources that may fail, reload, or mutate.
/// - Encapsulating loading, success, and error states via Riverpod's [AsyncValue].
/// - Calling domain use cases returning [Result] and translating them safely.
///
/// Key rules demonstrated:
/// - Initial loading is performed in [build] returning a [Future].
/// - Mutations use `state = const AsyncLoading()` while in flight.
/// - Asynchronous gaps are guarded with `if (!ref.mounted) return;`.
/// - Failures are cleanly folded into [AsyncError].
class TemplateAsyncNotifier<T> extends AsyncNotifier<T> {
  TemplateAsyncNotifier({
    required Future<Result<T>> Function() fetchInitial,
    required Future<Result<T>> Function(T current, dynamic delta) mutateAction,
  }) : _fetchInitial = fetchInitial,
       _mutateAction = mutateAction;

  final Future<Result<T>> Function() _fetchInitial;
  final Future<Result<T>> Function(T current, dynamic delta) _mutateAction;

  @override
  Future<T> build() async {
    final result = await _fetchInitial();
    return switch (result) {
      Success(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Mutates the current value using the provided [delta].
  ///
  /// Demonstrates the safe mutation pattern with `ref.mounted` guard.
  Future<bool> mutate(dynamic delta) async {
    final currentValue = state.value;
    if (currentValue == null || state.isLoading) return false;

    state = const AsyncLoading();

    final result = await _mutateAction(currentValue, delta);

    // Riverpod 3 lifecycle guard: do not touch state if disposed while awaiting.
    if (!ref.mounted) return false;

    return result.fold(
      onSuccess: (updated) {
        state = AsyncData(updated);
        return true;
      },
      onErr: (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }

  /// Invalidate and re-run the build method.
  void refresh() => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// 3. Reactive Stream State Template (StreamNotifier)
// ---------------------------------------------------------------------------

/// Canonical template for a reactive stream notifier.
///
/// Use this pattern for:
/// - Live subscriptions to Drift queries or repository reactive streams.
/// - Transforming raw domain [Stream] of [Result] into UI state.
///
/// Example:
/// ```dart
/// class LiveItemsNotifier extends StreamNotifier<List<Item>> {
///   @override
///   Stream<List<Item>> build() {
///     final watchUseCase = ref.watch(watchItemsProvider);
///     return watchUseCase(const NoParams()).map(
///       (result) => result.fold(
///         onSuccess: (items) => items,
///         onErr: (failure) => const <Item>[],
///       ),
///     );
///   }
///
///   void refresh() => ref.invalidateSelf();
/// }
/// ```
abstract class TemplateStreamNotifier<T> extends StreamNotifier<T> {
  /// Force-refreshes the stream by invalidating the notifier.
  void refresh() => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// 4. Use Case Bridge Template Helper
// ---------------------------------------------------------------------------

/// Canonical helper template for bridging Clean Architecture use cases into
/// Riverpod.
///
/// Stateless use cases are exposed via standard [Provider]s (not auto-disposed)
/// because allocating a new use case on every UI rebuild is unnecessary churn.
///
/// Example:
/// ```dart
/// final myUseCaseProvider = Provider<MyUseCase>((ref) => getIt<MyUseCase>());
/// ```
Provider<U> createUseCaseBridge<U extends Object>(U Function() resolve) =>
    Provider<U>((_) => resolve());
