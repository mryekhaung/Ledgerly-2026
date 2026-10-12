import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/domain/usecases/delete_category.dart';
import 'package:ledgerly/features/categories/domain/usecases/get_category.dart';
import 'package:ledgerly/features/categories/domain/usecases/save_category.dart';
import 'package:ledgerly/features/categories/domain/validators/category_validators.dart';

import 'fake_category_repository.dart';

/// Use-case tests. Each one asserts the *decision* the use case makes — which
/// repository method it called, with what — because that decision is the only
/// reason the class exists; the repository is a fake.
void main() {
  late FakeCategoryRepository repository;

  setUp(() {
    repository = FakeCategoryRepository(
      seed: <Category>[fakeCategory(id: 'cat-food', name: 'Food')],
    );
    addTearDown(repository.dispose);
  });

  group('SaveCategory', () {
    const validDraft = (
      name: 'Travel',
      iconKey: 'flight',
      colorValue: 0xFF5A8FE8,
      kind: CategoryKind.expense,
    );

    test('should_create_when_id_is_null', () async {
      final result = await SaveCategory(repository)((
        id: null,
        draft: validDraft,
      ));

      expect(result.isSuccess, isTrue);
      expect(repository.createdDrafts.length, 1);
      expect(repository.updatedIds, isEmpty);
    });

    test('should_update_when_id_is_provided', () async {
      final result = await SaveCategory(repository)((
        id: 'cat-food',
        draft: validDraft,
      ));

      expect(result.isSuccess, isTrue);
      expect(repository.updatedIds, ['cat-food']);
      expect(repository.createdDrafts, isEmpty);
    });

    test('should_trim_the_name_when_storing', () async {
      await SaveCategory(repository)((
        id: null,
        draft: (
          name: '  Travel  ',
          iconKey: 'flight',
          colorValue: 0xFF5A8FE8,
          kind: CategoryKind.expense,
        ),
      ));

      expect(repository.createdDrafts.single.name, 'Travel');
    });

    test('should_fail_with_a_name_field_error_when_name_is_blank', () async {
      final result = await SaveCategory(repository)((
        id: null,
        draft: (
          name: '   ',
          iconKey: 'flight',
          colorValue: 0xFF5A8FE8,
          kind: CategoryKind.expense,
        ),
      ));

      final failure = result.failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure! as ValidationFailure).fieldErrors['name'],
        CategoryValidators.nameRequired,
      );
      expect(repository.createdDrafts, isEmpty);
    });

    test('should_not_ask_the_repository_when_the_name_is_blank', () async {
      // A blank name is rejected locally, so the uniqueness query is skipped —
      // asserting the *absence* of a call is what keeps a future refactor from
      // reintroducing a pointless round trip on every keystroke.
      await SaveCategory(repository)((
        id: null,
        draft: (
          name: '',
          iconKey: 'flight',
          colorValue: 0xFF5A8FE8,
          kind: CategoryKind.expense,
        ),
      ));

      expect(repository.nameExistsCalls, isEmpty);
    });

    test('should_fail_when_the_name_is_already_taken', () async {
      final result = await SaveCategory(repository)((
        id: null,
        draft: (
          name: 'Food',
          iconKey: 'restaurant',
          colorValue: 0xFFE8735A,
          kind: CategoryKind.expense,
        ),
      ));

      expect(
        (result.failureOrNull! as ValidationFailure).fieldErrors['name'],
        CategoryValidators.nameTaken,
      );
      expect(repository.createdDrafts, isEmpty);
    });

    test('should_exclude_its_own_id_when_checking_uniqueness', () async {
      // An edit that leaves the name unchanged must not conflict with itself.
      await SaveCategory(repository)((
        id: 'cat-food',
        draft: (
          name: 'Food',
          iconKey: 'restaurant',
          colorValue: 0xFFE8735A,
          kind: CategoryKind.expense,
        ),
      ));

      expect(repository.nameExistsCalls.single.excludingId, 'cat-food');
    });

    test('should_not_treat_its_own_name_as_taken_when_editing', () async {
      final result = await SaveCategory(repository)((
        id: 'cat-food',
        draft: (
          name: 'Food',
          iconKey: 'restaurant',
          colorValue: 0xFFE8735A,
          kind: CategoryKind.expense,
        ),
      ));

      expect(result.isSuccess, isTrue);
    });

    test('should_match_existing_names_case_insensitively', () async {
      final result = await SaveCategory(repository)((
        id: null,
        draft: (
          name: 'food',
          iconKey: 'restaurant',
          colorValue: 0xFFE8735A,
          kind: CategoryKind.expense,
        ),
      ));

      expect(
        (result.failureOrNull! as ValidationFailure).fieldErrors['name'],
        CategoryValidators.nameTaken,
      );
    });

    test('should_report_an_icon_field_error_when_the_icon_is_blank', () async {
      final result = await SaveCategory(repository)((
        id: null,
        draft: (
          name: 'Travel',
          iconKey: '',
          colorValue: 0xFF5A8FE8,
          kind: CategoryKind.expense,
        ),
      ));

      expect(
        (result.failureOrNull! as ValidationFailure).fieldErrors['iconKey'],
        CategoryValidators.iconRequired,
      );
    });

    test(
      'should_report_a_colour_field_error_when_the_colour_is_transparent',
      () async {
        final result = await SaveCategory(repository)((
          id: null,
          draft: (
            name: 'Travel',
            iconKey: 'flight',
            colorValue: 0,
            kind: CategoryKind.expense,
          ),
        ));

        expect(
          (result.failureOrNull! as ValidationFailure)
              .fieldErrors['colorValue'],
          CategoryValidators.colorInvalid,
        );
      },
    );

    test('should_propagate_a_repository_failure_unchanged', () async {
      // A storage problem is not a validation problem: the failure must arrive
      // intact so the UI can show "storage" rather than marking a field.
      repository.forcedFailure = const StorageFailure('disk full');

      final result = await SaveCategory(repository)((
        id: null,
        draft: validDraft,
      ));

      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('should_propagate_a_failure_from_the_uniqueness_lookup', () async {
      // The lookup runs before validation, so its failure must surface rather
      // than being swallowed and reported as a validation error.
      repository.forcedFailure = const StorageFailure('unavailable');

      final result = await SaveCategory(repository)((
        id: null,
        draft: validDraft,
      ));

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('GetCategory', () {
    test('should_return_the_category_when_it_is_live', () async {
      final result = await GetCategory(repository)((id: 'cat-food'));

      expect(result.valueOrNull?.name, 'Food');
    });

    test('should_fail_with_not_found_when_the_category_is_missing', () async {
      final result = await GetCategory(repository)((id: 'nope'));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
      'should_fail_with_not_found_when_the_category_is_soft_deleted',
      () async {
        // A soft-deleted row is still on disk; the domain must treat it as gone so
        // an edit form opened from a stale route cannot resurrect it.
        final softDeleted = FakeCategoryRepository(
          seed: <Category>[fakeCategory(id: 'cat-1', deletedAt: 500)],
        );
        addTearDown(softDeleted.dispose);

        final result = await GetCategory(softDeleted)((id: 'cat-1'));

        expect(result.failureOrNull, isA<NotFoundFailure>());
      },
    );
  });

  group('DeleteCategory', () {
    test('should_soft_delete_when_the_category_exists', () async {
      final result = await DeleteCategory(repository)((id: 'cat-food'));

      expect(result.isSuccess, isTrue);
      // Still on disk — the tombstone is what a sync propagates
      // (docs/Architecture.md ADR #4).
      expect(repository.items.single.deletedAt, isNotNull);
    });

    test('should_fail_with_not_found_when_the_category_is_missing', () async {
      final result = await DeleteCategory(repository)((id: 'nope'));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('RestoreCategory', () {
    test('should_clear_the_tombstone_after_a_delete', () async {
      await DeleteCategory(repository)((id: 'cat-food'));
      expect(repository.items.single.deletedAt, isNotNull);

      final result = await RestoreCategory(repository)((id: 'cat-food'));

      expect(result.isSuccess, isTrue);
      expect(repository.items.single.deletedAt, isNull);
      expect(repository.restoredIds, <String>['cat-food']);
    });

    test('should_keep_the_original_id_and_timestamps', () async {
      // The reason restore is not a re-create: a transaction that referenced the
      // category still resolves only if the id survives.
      final before = repository.items.single;
      await DeleteCategory(repository)((id: 'cat-food'));

      await RestoreCategory(repository)((id: 'cat-food'));

      final after = repository.items.single;
      expect(after.id, before.id);
      expect(after.createdAt, before.createdAt);
      expect(after.name, before.name);
    });

    test('should_fail_with_not_found_when_the_category_is_missing', () async {
      final result = await RestoreCategory(repository)((id: 'nope'));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('should_propagate_a_forced_failure', () async {
      repository.forcedFailure = const StorageFailure('disk');

      final result = await RestoreCategory(repository)((id: 'cat-food'));

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('SetCategoryArchived', () {
    test('should_archive_without_deleting', () async {
      final result = await SetCategoryArchived(repository)((
        id: 'cat-food',
        isArchived: true,
      ));

      expect(result.isSuccess, isTrue);
      final stored = repository.items.single;
      expect(stored.isArchived, isTrue);
      expect(stored.deletedAt, isNull);
    });

    test('should_unarchive_when_asked', () async {
      await SetCategoryArchived(repository)((id: 'cat-food', isArchived: true));
      final result = await SetCategoryArchived(repository)((
        id: 'cat-food',
        isArchived: false,
      ));

      expect(result.isSuccess, isTrue);
      expect(repository.items.single.isArchived, isFalse);
    });
  });

  group('ReorderCategories', () {
    test('should_rewrite_sort_order_when_ids_are_given', () async {
      final seeded = FakeCategoryRepository(
        seed: <Category>[
          fakeCategory(id: 'a', name: 'A', sortOrder: 0),
          fakeCategory(id: 'b', name: 'B', sortOrder: 1),
          fakeCategory(id: 'c', name: 'C', sortOrder: 2),
        ],
      );
      addTearDown(seeded.dispose);

      final result = await ReorderCategories(seeded)((
        orderedIds: ['c', 'a', 'b'],
      ));

      expect(result.isSuccess, isTrue);
      expect(seeded.items.map((c) => c.id).toList(), [
        'a',
        'b',
        'c',
      ], reason: 'the backing list keeps insertion order');
      final byId = {for (final c in seeded.items) c.id: c.sortOrder};
      expect(byId['c'], 0);
      expect(byId['a'], 1);
      expect(byId['b'], 2);
    });

    test(
      'should_fail_without_touching_the_repository_when_ids_are_empty',
      () async {
        // An empty reorder is a UI bug (a grid that failed to build). Reaching the
        // repository would rewrite every sortOrder to nothing.
        final result = await ReorderCategories(repository)((
          orderedIds: const <String>[],
        ));

        expect(result.failureOrNull, isA<UnexpectedFailure>());
      },
    );
  });
}
