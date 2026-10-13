import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/app_database.dart' as db;
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/features/categories/data/datasources/category_local_datasource.dart';
import 'package:ledgerly/features/categories/data/mappers/category_mapper.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';

import 'category_data_harness.dart';

/// Data-layer tests for categories: a real in-memory Drift database, the real
/// datasource, the real mapper. Nothing is mocked, because the thing under test
/// *is* the translation between storage and domain.
void main() {
  late CategoryDataHarness harness;

  setUp(() {
    harness = CategoryDataHarness.over(db.AppDatabase(NativeDatabase.memory()));
    addTearDown(harness.dispose);
  });

  group('CategoryMapper.toEntity', () {
    // Built through the datasource rather than a raw insert, so every
    // assertion below is about a row the app itself could have written.
    test('should_round_trip_every_field', () async {
      await harness.datasource.create((
        name: 'Travel',
        iconKey: 'flight',
        colorValue: 0xFF5A8FE8,
        kind: CategoryKind.income,
      ));

      final stored = expectSuccess(await harness.repository.watchAll().first)
          .single;

      expect(stored.id, 'id-0');
      expect(stored.name, 'Travel');
      expect(stored.iconKey, 'flight');
      expect(stored.colorValue, 0xFF5A8FE8);
      expect(stored.kind, CategoryKind.income);
      expect(stored.sortOrder, 0);
      expect(stored.isArchived, isFalse);
      expect(stored.isDefault, isFalse);
      expect(stored.createdAt, 1000);
      expect(stored.updatedAt, 1000);
      expect(stored.deletedAt, isNull);
    });

    test(
      'should_fall_back_to_expense_when_the_stored_kind_is_unknown',
      () async {
        // A row written by a newer build (or a hand-edited file) must not crash
        // the list page — see the mapper's doc for why a fallback is safer here
        // than throwing, unlike the transaction direction.
        await harness.db.customStatement(
          'INSERT INTO categories '
          '(id, name, icon_key, color_value, kind, sort_order, is_archived, '
          'is_default, created_at, updated_at) '
          "VALUES ('x', 'Weird', 'tag', 4278190080, 'nonsense', 0, 0, 0, 1, 1)",
        );

        final all = expectSuccess(await harness.repository.watchAll().first);
        expect(all.single.kind, CategoryKind.expense);
      },
    );
  });

  group('CategoryLocalDataSource.create', () {
    test('should_use_the_injected_id_generator', () async {
      final created = await harness.datasource.create((
        name: 'A',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));

      expect(created.id, 'id-0');
    });

    test('should_increment_ids_across_creates', () async {
      await harness.datasource.create((
        name: 'A',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      final second = await harness.datasource.create((
        name: 'B',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));

      expect(second.id, 'id-1');
    });

    test('should_assign_dense_sort_orders_matching_insert_order', () async {
      for (final name in ['A', 'B', 'C']) {
        await harness.datasource.create((
          name: name,
          iconKey: 'tag',
          colorValue: 0xFF112233,
          kind: CategoryKind.expense,
        ));
      }

      final all = expectSuccess(await harness.repository.watchAll().first);
      expect(all.map((c) => c.name).toList(), ['A', 'B', 'C']);
      expect(all.map((c) => c.sortOrder).toList(), [0, 1, 2]);
    });

    test('should_stamp_created_and_updated_from_the_injected_clock', () async {
      harness.clock.advance(const Duration(milliseconds: 500));
      final created = await harness.datasource.create((
        name: 'A',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));

      expect(created.createdAt, 1500);
      expect(created.updatedAt, 1500);
    });
  });

  group('CategoryLocalDataSource.update', () {
    test('should_change_only_the_supplied_fields', () async {
      await harness.datasource.create((
        name: 'A',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      harness.clock.advance(const Duration(milliseconds: 1000));

      final updated = await harness.datasource.update('id-0', (
        name: 'Renamed',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));

      expect(updated.name, 'Renamed');
      expect(updated.createdAt, 1000, reason: 'createdAt is never rewritten');
      expect(updated.updatedAt, 2000);
    });

    test('should_throw_when_the_category_does_not_exist', () async {
      // The repository turns this into a `NotFoundFailure`; asserting the throw
      // here is what proves the contract at the datasource boundary.
      await expectLater(
        harness.datasource.update('missing', (
          name: 'A',
          iconKey: 'tag',
          colorValue: 0xFF112233,
          kind: CategoryKind.expense,
        )),
        throwsA(isA<CategoryNotFoundException>()),
      );
    });
  });

  group('CategoryLocalDataSource reads', () {
    test('should_order_archived_last_when_watching_all', () async {
      await harness.datasource.create((
        name: 'Active',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      await harness.datasource.create((
        name: 'Retired',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      await harness.datasource.setArchived('id-1', isArchived: true);

      final all = expectSuccess(await harness.repository.watchAll().first);

      expect(all.map((c) => c.name).toList(), ['Active', 'Retired']);
    });

    test('should_hide_archived_categories_from_the_picker', () async {
      await harness.datasource.create((
        name: 'Retired',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      await harness.datasource.setArchived('id-0', isArchived: true);

      final pickable = expectSuccess(
        await harness.repository
            .watchPickable(kind: CategoryKind.expense)
            .first,
      );

      expect(pickable, isEmpty);
    });

    test('should_filter_the_picker_by_kind', () async {
      await harness.datasource.create((
        name: 'Out',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      await harness.datasource.create((
        name: 'In',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.income,
      ));

      final income = expectSuccess(
        await harness.repository.watchPickable(kind: CategoryKind.income).first,
      );

      expect(income.map((c) => c.name).toList(), ['In']);
    });

    test('should_exclude_soft_deleted_categories_from_watch_all', () async {
      await harness.datasource.create((
        name: 'Gone',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      await harness.datasource.delete('id-0');

      final all = expectSuccess(await harness.repository.watchAll().first);

      expect(all, isEmpty);
    });

    test('should_return_null_when_findById_misses', () async {
      expect(await harness.datasource.findById('missing'), isNull);
    });

    test('should_return_null_when_findById_hits_a_soft_deleted_row', () async {
      await harness.datasource.create((
        name: 'Gone',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      await harness.datasource.delete('id-0');

      expect(await harness.datasource.findById('id-0'), isNull);
    });

    test('should_bring_a_soft_deleted_row_back_on_restore', () async {
      await harness.datasource.create((
        name: 'Food',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      final original = await harness.datasource.findById('id-0');
      await harness.datasource.delete('id-0');
      expect(await harness.datasource.findById('id-0'), isNull);

      await harness.datasource.restore('id-0');

      final restored = await harness.datasource.findById('id-0');
      expect(restored, isNotNull);
      // The *same* row, not a new one: the id is what transactions reference.
      expect(restored!.id, original!.id);
      expect(restored.createdAt, original.createdAt);
      // `updatedAt` moves because the restore is a write; `deletedAt` clears.
      expect(restored.updatedAt, greaterThanOrEqualTo(original.updatedAt));
    });

    test('should_reappear_in_watch_all_after_restore', () async {
      await harness.datasource.create((
        name: 'Food',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      await harness.datasource.delete('id-0');
      expect(expectSuccess(await harness.repository.watchAll().first), isEmpty);

      await harness.datasource.restore('id-0');

      final all = expectSuccess(await harness.repository.watchAll().first);
      expect(all.map((c) => c.name).toList(), ['Food']);
    });

    test('should_be_a_no_op_when_restoring_a_live_row', () async {
      // A double-tap on Undo must not corrupt anything, so the write is
      // unconditional and idempotent rather than guarded by a read.
      await harness.datasource.create((
        name: 'Food',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));

      await harness.datasource.restore('id-0');

      final row = await harness.datasource.findById('id-0');
      expect(row, isNotNull);
      expect(row!.name, 'Food');
    });
  });

  group('CategoryLocalDataSource.reorder', () {
    test('should_rewrite_sort_order_to_match_the_given_ids', () async {
      for (final name in ['A', 'B', 'C']) {
        await harness.datasource.create((
          name: name,
          iconKey: 'tag',
          colorValue: 0xFF112233,
          kind: CategoryKind.expense,
        ));
      }

      await harness.datasource.reorder(['id-2', 'id-0', 'id-1']);

      final all = expectSuccess(await harness.repository.watchAll().first);
      expect(all.map((c) => c.id).toList(), ['id-2', 'id-0', 'id-1']);
      expect(all.map((c) => c.sortOrder).toList(), [0, 1, 2]);
    });
  });

  group('CategoryLocalDataSource.nameExists', () {
    test('should_match_case_insensitively', () async {
      await harness.datasource.create((
        name: 'Food',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));

      expect(await harness.datasource.nameExists('food'), isTrue);
    });

    test('should_ignore_the_excluded_id', () async {
      await harness.datasource.create((
        name: 'Food',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));

      expect(
        await harness.datasource.nameExists('Food', excludingId: 'id-0'),
        isFalse,
      );
    });

    test('should_ignore_soft_deleted_rows', () async {
      // A deleted `Food` must not block recreating `Food` — that is why
      // uniqueness is checked here and not by a UNIQUE index.
      await harness.datasource.create((
        name: 'Food',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      await harness.datasource.delete('id-0');

      expect(await harness.datasource.nameExists('Food'), isFalse);
    });
  });

  group('CategoryRepositoryImpl failure mapping', () {
    test('should_return_not_found_when_updating_a_missing_row', () async {
      final result = await harness.repository.update('missing', (
        name: 'A',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('should_return_not_found_when_reading_a_soft_deleted_row', () async {
      await harness.datasource.create((
        name: 'Gone',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
      ));
      await harness.datasource.delete('id-0');

      final result = await harness.repository.findById('id-0');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('should_map_a_storage_error_when_the_query_fails', () async {
      // Provoke a real engine error: drop the table out from under the query, so
      // the next `SELECT` fails in SQLite with "no such table". The guard must
      // catch it and hand back a `StorageFailure` rather than letting the
      // exception escape `data/` (docs/Agent.md §3.4).
      //
      // Closing the connection was the original approach here, but drift reopens
      // a `DelegatedDatabase` lazily on the next operation, so both a read and a
      // write quietly succeeded against the "closed" handle and the test proved
      // nothing. A corrupt row was the second attempt, and does not work either:
      // `CategoryMapper` decodes every field defensively (an unknown `kind` falls
      // back to `expense` on purpose), so no row can make it throw.
      await harness.db.customStatement('DROP TABLE categories');

      final result = await harness.repository.watchAll().first;

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('Category entity copyWith', () {
    test('should_clear_deletedAt_only_when_the_flag_is_set', () {
      const base = Category(
        id: 'c',
        name: 'Food',
        iconKey: 'tag',
        colorValue: 0xFF112233,
        kind: CategoryKind.expense,
        sortOrder: 0,
        isArchived: false,
        isDefault: false,
        createdAt: 1,
        updatedAt: 1,
        deletedAt: 99,
      );

      expect(base.copyWith(name: 'X').deletedAt, 99);
      expect(base.copyWith(clearDeletedAt: true).deletedAt, isNull);
    });
  });

  group('CategoryMapper insert/update companions', () {
    test('should_materialise_every_editable_field_when_updating', () {
      final companion = CategoryMapper.toUpdateCompanion(
        draft: (
          name: 'A',
          iconKey: 'tag',
          colorValue: 0xFF112233,
          kind: CategoryKind.income,
        ),
        nowUtcMillis: 500,
      );

      // An absent field would silently keep a value the user just changed.
      expect(companion.name.present, isTrue);
      expect(companion.iconKey.present, isTrue);
      expect(companion.colorValue.present, isTrue);
      expect(companion.kind.present, isTrue);
      expect(companion.updatedAt.present, isTrue);
    });
  });
}
