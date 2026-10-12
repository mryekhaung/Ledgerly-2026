import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/category_list_state.dart';

import '../domain/fake_category_repository.dart';

/// Tests for the pure part of the categories list state.
///
/// The split between active and archived is exactly the kind of logic that is
/// easy to get subtly wrong (losing order, dropping the archived section) and
/// expensive to debug through a widget tree, so it is extracted and tested here
/// (`docs/Agent.md` §6).
void main() {
  group('CategoryListState.of', () {
    test('should_split_active_from_archived', () {
      final state = CategoryListState.of(<Category>[
        fakeCategory(id: 'a', name: 'Food'),
        fakeCategory(id: 'b', name: 'Old', isArchived: true),
        fakeCategory(id: 'c', name: 'Transport'),
      ]);

      expect(state.active.map((c) => c.id).toList(), ['a', 'c']);
      expect(state.archived.map((c) => c.id).toList(), ['b']);
    });

    test('should_preserve_manual_order_rather_than_re_sorting', () {
      // The DAO already ordered by `sortOrder`; re-sorting here would silently
      // override the order the user dragged into place.
      final state = CategoryListState.of(<Category>[
        fakeCategory(id: 'z', name: 'Zebra', sortOrder: 0),
        fakeCategory(id: 'a', name: 'Apple', sortOrder: 1),
      ]);

      expect(state.active.map((c) => c.id).toList(), ['z', 'a']);
    });

    test('should_stay_empty_when_only_a_failure_is_present', () {
      final state = CategoryListState.of(const <Category>[]);

      expect(state.isEmpty, isTrue);
      expect(state.isFirstLoad, isTrue);
      expect(state.failure, isNull);
    });
  });

  group('CategoryListState.from', () {
    test('should_carry_the_failure_and_drop_the_rows_when_the_load_failed', () {
      // A failed load must not show a banner over rows that are no longer
      // trustworthy — the lists go empty alongside the failure.
      final state = CategoryListState.from(
        const Err<List<Category>>(StorageFailure('boom')),
      );

      expect(state.active, isEmpty);
      expect(state.archived, isEmpty);
      expect(state.failure, isA<StorageFailure>());
      expect(state.isEmpty, isTrue);
      expect(
        state.isFirstLoad,
        isFalse,
        reason: 'a failure is not a first load',
      );
    });

    test('should_split_when_the_load_succeeded', () {
      final state = CategoryListState.from(
        Success<List<Category>>(<Category>[fakeCategory(id: 'a')]),
      );

      expect(state.active.map((c) => c.id).toList(), ['a']);
      expect(state.failure, isNull);
    });
  });

  group('CategoryListState.empty', () {
    test('should_report_a_first_load', () {
      const state = CategoryListState.empty();

      expect(state.isEmpty, isTrue);
      expect(state.isFirstLoad, isTrue);
    });

    test('should_not_be_a_first_load_once_a_failure_is_recorded', () {
      const state = CategoryListState(
        active: <Category>[],
        archived: <Category>[],
        failure: UnexpectedFailure('x'),
      );

      expect(state.isFirstLoad, isFalse);
    });
  });
}
