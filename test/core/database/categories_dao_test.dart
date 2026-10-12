import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/daos/categories_dao.dart';
import 'package:ledgerly/core/database/seed.dart';

import 'db_harness.dart';

/// Covers `CategoriesDao` against a real in-memory SQLite database.
///
/// The behaviours pinned here are the ones a refactor could silently break: the
/// soft-delete filter on every read, `nameExists` ignoring deleted rows, and the
/// `sortOrder` invariant the list drag-to-reorder gesture depends on.
void main() {
  group('CategoriesDao.insert', () {
    test('should_assign_a_uuid_and_append_to_the_end', () async {
      final h = useDbHarness();
      final first = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 0xFFE8735A,
      );
      final second = await h.categories.insert(
        name: 'Transport',
        iconKey: 'directions_bus',
        colorValue: 0xFF5A8FE8,
      );

      expect(first.length, 36, reason: 'a UUIDv4 string');
      expect((await h.categories.findById(first))!.sortOrder, 0);
      expect((await h.categories.findById(second))!.sortOrder, 1);
    });

    test('should_stamp_created_and_updated_from_the_clock', () async {
      final h = useDbHarness(startMillis: 42);
      final id = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 0xFFE8735A,
      );

      final row = (await h.categories.findById(id))!;
      expect(row.createdAt, 42);
      expect(row.updatedAt, 42);
      expect(row.deletedAt, isNull, reason: 'a new row is live');
      expect(row.isArchived, isFalse);
      expect(row.isDefault, isFalse);
      expect(row.kind, 'expense', reason: 'the column default');
    });

    test('should_keep_the_kind_it_was_given', () async {
      final h = useDbHarness();
      final id = await h.categories.insert(
        name: 'Salary',
        iconKey: 'payments',
        colorValue: 0xFF6FB98F,
        kind: 'income',
      );

      expect((await h.categories.findById(id))!.kind, 'income');
    });
  });

  group('CategoriesDao.watchAll', () {
    test('should_order_by_archive_then_sort_order', () async {
      final h = useDbHarness();
      final b = await h.categories.insert(
        name: 'B',
        iconKey: 'x',
        colorValue: 1,
        sortOrder: 1,
      );
      final a = await h.categories.insert(
        name: 'A',
        iconKey: 'x',
        colorValue: 1,
        sortOrder: 0,
      );
      // Archived rows sort last even when their sortOrder is smallest.
      final z = await h.categories.insert(
        name: 'Z',
        iconKey: 'x',
        colorValue: 1,
        sortOrder: -5,
        isArchived: true,
      );

      final ids = (await h.categories.watchAll().first)
          .map((c) => c.id)
          .toList();
      expect(ids, [a, b, z]);
    });
  });

  group('CategoriesDao.watchPickable', () {
    test('should_exclude_archived_and_wrong_kind_rows', () async {
      final h = useDbHarness();
      final expense = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );
      await h.categories.insert(
        name: 'Salary',
        iconKey: 'payments',
        colorValue: 2,
        kind: 'income',
      );
      final archived = await h.categories.insert(
        name: 'Rent',
        iconKey: 'home',
        colorValue: 3,
        isArchived: true,
      );

      final pickable = await h.categories.watchPickable(kind: 'expense').first;
      expect(pickable.map((c) => c.id), [
        expense,
      ], reason: 'archived rows are excluded even for a matching kind');
      expect(
        (await h.categories.watchAll().first).map((c) => c.id),
        contains(archived),
        reason: 'but they are still listed',
      );
    });
  });

  group('CategoriesDao.setArchived', () {
    test('should_hide_from_pickable_but_keep_in_watchAll', () async {
      // The whole reason `isArchived` exists separately from `deletedAt`
      // (`docs/DataModel.md` §2): retiring "Rent" should drop it out of the
      // picker without erasing last year's chart.
      final h = useDbHarness(startMillis: 100);
      final id = await h.categories.insert(
        name: 'Rent',
        iconKey: 'home',
        colorValue: 1,
      );
      h.clock.advance(const Duration(seconds: 4));

      await h.categories.setArchived(id, isArchived: true);

      expect(
        await h.categories.watchPickable(kind: 'expense').first,
        isEmpty,
        reason: 'archived rows are not offered in the picker',
      );
      final all = await h.categories.watchAll().first;
      expect(all.single.id, id, reason: 'but they remain in the list');
      expect(all.single.updatedAt, 4100);
      expect(all.single.deletedAt, isNull);
    });

    test('should_unarchive', () async {
      final h = useDbHarness();
      final id = await h.categories.insert(
        name: 'Rent',
        iconKey: 'home',
        colorValue: 1,
        isArchived: true,
      );

      await h.categories.setArchived(id, isArchived: false);

      expect((await h.categories.findById(id))!.isArchived, isFalse);
      expect(
        (await h.categories.watchPickable(kind: 'expense').first).single.id,
        id,
      );
    });
  });

  group('CategoriesDao.updateById', () {
    test('should_change_fields_and_bump_updated_at_only', () async {
      final h = useDbHarness(startMillis: 100);
      final id = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 0xFFE8735A,
      );
      h.clock.advance(const Duration(seconds: 5));

      await h.categories.updateById(
        id,
        name: 'Dining',
        iconKey: 'local_cafe',
        colorValue: 0xFF123456,
      );

      final row = (await h.categories.findById(id))!;
      expect(row.name, 'Dining');
      expect(row.iconKey, 'local_cafe');
      expect(row.colorValue, 0xFF123456);
      expect(row.updatedAt, 5100);
      expect(row.createdAt, 100, reason: 'createdAt is never rewritten');
    });

    test('should_leave_omitted_fields_alone', () async {
      final h = useDbHarness();
      final id = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 0xFFE8735A,
        kind: 'income',
      );

      await h.categories.updateById(id, name: 'Dining');

      final row = (await h.categories.findById(id))!;
      expect(row.name, 'Dining');
      expect(row.iconKey, 'restaurant', reason: 'not passed, so unchanged');
      expect(row.kind, 'income');
    });
  });

  group('CategoriesDao.nameExists', () {
    test('should_find_an_active_name_and_ignore_a_deleted_one', () async {
      final h = useDbHarness();
      final id = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      expect(await h.categories.nameExists('Food'), isTrue);

      await h.categories.softDelete(id);

      expect(
        await h.categories.nameExists('Food'),
        isFalse,
        reason: 'a soft-deleted Food must not block recreating Food',
      );
    });

    test('should_exclude_the_row_being_edited', () async {
      final h = useDbHarness();
      final id = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      expect(
        await h.categories.nameExists('Food', excludingId: id),
        isFalse,
        reason: 'renaming a row to its own current name is not a conflict',
      );
    });

    test('should_still_report_a_clash_with_a_different_row', () async {
      final h = useDbHarness();
      await h.categories.insert(name: 'Food', iconKey: 'a', colorValue: 1);
      final other = await h.categories.insert(
        name: 'Transport',
        iconKey: 'b',
        colorValue: 2,
      );

      expect(await h.categories.nameExists('Food', excludingId: other), isTrue);
    });
  });

  group('CategoriesDao.softDelete', () {
    test('should_hide_the_row_without_removing_it', () async {
      final h = useDbHarness(startMillis: 100);
      final id = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );
      h.clock.advance(const Duration(milliseconds: 1));

      await h.categories.softDelete(id);

      expect(await h.categories.findById(id), isNull);
      expect(await h.categories.watchAll().first, isEmpty);
      expect(
        await physicalRowCount(h.db, h.db.categories),
        1,
        reason:
            'soft delete is an UPDATE (ADR #4) — the row stays for sync/undo',
      );
      expect(await rawValue(h.db, 'categories', 'deleted_at', id), 101);
    });
  });

  group('CategoriesDao.reorder', () {
    test('should_rewrite_sort_order_densely_in_the_given_order', () async {
      final h = useDbHarness();
      final a = await h.categories.insert(
        name: 'A',
        iconKey: 'x',
        colorValue: 1,
        sortOrder: 0,
      );
      final b = await h.categories.insert(
        name: 'B',
        iconKey: 'x',
        colorValue: 1,
        sortOrder: 1,
      );
      final c = await h.categories.insert(
        name: 'C',
        iconKey: 'x',
        colorValue: 1,
        sortOrder: 2,
      );

      await h.categories.reorder([c, a, b]);

      final order = await h.categories.watchAll().first;
      expect(order.map((e) => e.id).toList(), [c, a, b]);
      expect(order.map((e) => e.sortOrder).toList(), [0, 1, 2]);
    });

    test('should_bump_updated_at_on_every_moved_row', () async {
      final h = useDbHarness(startMillis: 100);
      final a = await h.categories.insert(
        name: 'A',
        iconKey: 'x',
        colorValue: 1,
      );
      final b = await h.categories.insert(
        name: 'B',
        iconKey: 'x',
        colorValue: 1,
      );
      h.clock.advance(const Duration(seconds: 1));

      await h.categories.reorder([b, a]);

      expect((await h.categories.findById(a))!.updatedAt, 1100);
      expect((await h.categories.findById(b))!.updatedAt, 1100);
    });
  });
}
