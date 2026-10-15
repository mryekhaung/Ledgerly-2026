import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/seed.dart';
import 'package:ledgerly/features/categories/presentation/category_catalog.dart';

import 'db_harness.dart';

/// Covers the first-launch seed (`docs/DataModel.md` §6).
///
/// The seed is a *data* concern with a UI-visible contract: the Calendar page's
/// category picker must never open empty on a fresh install, and a user who
/// deliberately deletes every category must not have them reappear. Both halves
/// of that are asserted here.
void main() {
  group('defaultCategories', () {
    test('should_hold_the_documented_nine_expense_and_two_income_rows', () {
      final expense = defaultCategories
          .where((c) => c.kind == 'expense')
          .toList();
      final income = defaultCategories
          .where((c) => c.kind == 'income')
          .toList();

      expect(defaultCategories.length, 11);
      expect(expense.map((c) => c.name), [
        'Food',
        'Transport',
        'Groceries',
        'Bills',
        'Health',
        'Shopping',
        'Entertainment',
        'Education',
        'Other',
      ]);
      expect(income.map((c) => c.name), ['Salary', 'Other Income']);
    });

    test('should_use_a_distinct_icon_key_per_row', () {
      // Two rows sharing an icon key would render identically in the picker and
      // make the list untappable in practice.
      final iconKeys = defaultCategories.map((c) => c.iconKey).toSet();
      expect(iconKeys.length, defaultCategories.length);
    });

    test('should_use_only_catalogue_vocabulary_icon_keys', () {
      // A key outside `CategoryIcons.keys` renders as the fallback glyph, so
      // one wrong key here turns that row — and, repeated, the whole list —
      // into identical tag icons.
      for (final category in defaultCategories) {
        expect(
          CategoryIcons.keys,
          contains(category.iconKey),
          reason: '${category.name} uses ${category.iconKey}',
        );
      }
    });

    test('should_resolve_every_seed_to_a_distinct_glyph', () {
      // Vocabulary membership alone is not enough: the mapping itself must
      // produce visibly different gems per row.
      final glyphs = defaultCategories
          .map((c) => CategoryIcons.iconFor(c.iconKey))
          .toSet();
      expect(glyphs.length, defaultCategories.length);
    });

    test('should_give_every_row_an_opaque_argb32_colour', () {
      for (final category in defaultCategories) {
        expect(
          category.colorValue,
          inInclusiveRange(0xFF000000, 0xFFFFFFFF),
          reason: '${category.name} needs an ARGB32 value with a full alpha',
        );
      }
    });
  });

  group('seedDefaults', () {
    test('should_insert_every_default_row_and_report_the_count', () async {
      final h = useDbHarness();
      final inserted = await seedDefaults(h.db, clock: h.clock);

      expect(inserted, defaultCategories.length);
      expect(await physicalRowCount(h.db, h.db.categories), 11);
      expect((await h.categories.watchAll().first).length, 11);
    });

    test('should_write_a_dense_sort_order_in_list_order', () async {
      final h = useDbHarness();
      await seedDefaults(h.db, clock: h.clock);

      final rows = await h.categories.watchAll().first;
      expect(
        rows.map((c) => c.sortOrder).toList(),
        List<int>.generate(defaultCategories.length, (i) => i),
        reason: 'the picker renders in sortOrder, so the order must match §6',
      );
      expect(
        rows.map((c) => c.name).toList(),
        defaultCategories.map((c) => c.name).toList(),
      );
    });

    test('should_mark_every_seeded_row_as_default', () async {
      final h = useDbHarness();
      await seedDefaults(h.db, clock: h.clock);

      final rows = await h.categories.watchAll().first;
      expect(
        rows.every((c) => c.isDefault),
        isTrue,
        reason: 'isDefault is what a "restore defaults" action keys off',
      );
    });

    test('should_stamp_created_and_updated_from_the_clock', () async {
      final h = useDbHarness(startMillis: 4242);
      await seedDefaults(h.db, clock: h.clock);

      final rows = await h.categories.watchAll().first;
      expect(rows.every((c) => c.createdAt == 4242), isTrue);
      expect(rows.every((c) => c.updatedAt == 4242), isTrue);
      expect(rows.every((c) => c.deletedAt == null), isTrue);
    });

    test('should_assign_a_unique_uuid_per_row', () async {
      final h = useDbHarness();
      await seedDefaults(h.db, clock: h.clock);

      final ids = (await h.categories.watchAll().first)
          .map((c) => c.id)
          .toSet();
      expect(ids.length, defaultCategories.length);
      expect(ids.every((id) => id.length == 36), isTrue);
    });

    test('should_be_a_no_op_when_the_table_is_not_empty', () async {
      // The idempotence guard is by emptiness, not by a flag: a user who deletes
      // every category must not have them come back on the next launch, and a
      // user who has already been seeded must not get duplicates.
      final h = useDbHarness();
      await h.categories.insert(
        name: 'Only Mine',
        iconKey: 'star',
        colorValue: 0xFF123456,
      );

      final inserted = await seedDefaults(h.db, clock: h.clock);

      expect(inserted, 0, reason: '0 signals "skipped", not "failed"');
      final rows = await h.categories.watchAll().first;
      expect(rows.length, 1);
      expect(rows.single.name, 'Only Mine');
    });

    test('should_be_a_no_op_on_a_second_call', () async {
      final h = useDbHarness();
      final first = await seedDefaults(h.db, clock: h.clock);
      final second = await seedDefaults(h.db, clock: h.clock);

      expect(first, 11);
      expect(second, 0);
      expect(await physicalRowCount(h.db, h.db.categories), 11);
    });

    test('should_seed_by_the_physical_table_not_by_active_rows', () async {
      // A table whose every row is soft-deleted is *not* empty. Re-seeding would
      // resurrect the defaults next to the user's own tombstones.
      final h = useDbHarness();
      await seedDefaults(h.db, clock: h.clock);

      for (final row in await h.categories.watchAll().first) {
        await h.categories.softDelete(row.id);
      }

      final inserted = await seedDefaults(h.db, clock: h.clock);

      expect(inserted, 0);
      expect(await h.categories.watchAll().first, isEmpty);
      expect(await physicalRowCount(h.db, h.db.categories), 11);
    });

    test('should_use_the_injected_clock_not_the_wall_clock', () async {
      final h = useDbHarness();
      final clock = FixedClock(9000);

      await seedDefaults(h.db, clock: clock);

      final rows = await h.categories.watchAll().first;
      expect(rows.every((c) => c.createdAt == 9000), isTrue);
    });
  });
}
