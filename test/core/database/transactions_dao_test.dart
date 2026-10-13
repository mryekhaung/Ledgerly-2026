import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/local_date.dart';

import 'db_harness.dart';

/// Covers `TransactionsDao` against a real in-memory SQLite database.
///
/// Two things here are only testable with a real engine: the `LocalDate`
/// `TypeConverter` (the packed integer that actually lands on disk) and the SQL
/// aggregates (`SUM ... FILTER ... GROUP BY`), which the SQL-text probe cannot
/// execute. Both are load-bearing for the Calendar page.
void main() {
  group('TransactionsDao.insert', () {
    test('should_store_the_date_as_a_packed_integer', () async {
      final h = useDbHarness();
      final categoryId = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      final id = await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 12000,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );

      expect(
        await rawValue(h.db, 'transactions', 'date', id),
        20261003,
        reason: 'the converter must write yyyyMMdd, not a timestamp',
      );
      expect((await h.transactions.findById(id))!.date, october(3));
    });

    test('should_leave_account_null_when_not_given', () async {
      final h = useDbHarness();
      final categoryId = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      final id = await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );

      expect((await h.transactions.findById(id))!.accountId, isNull);
    });

    test('should_round_trip_a_note', () async {
      final h = useDbHarness();
      final categoryId = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      final id = await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
        note: 'lunch with Ko Aung',
      );

      expect((await h.transactions.findById(id))!.note, 'lunch with Ko Aung');
    });
  });

  group('TransactionsDao.watchDay', () {
    test('should_return_only_that_day_and_the_newest_write_first', () async {
      final h = useDbHarness();
      final categoryId = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      final first = await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 1,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      h.clock.advance(const Duration(seconds: 1));
      final second = await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 2,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 3,
        currency: 'mmk',
        direction: 'expense',
        date: october(4),
      );

      final day = await h.transactions.watchDay(october(3)).first;
      expect(day.map((t) => t.id).toList(), [second, first]);
    });

    test('should_exclude_a_soft_deleted_row', () async {
      final h = useDbHarness();
      final categoryId = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );
      final keep = await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 1,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      final drop = await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 2,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      await h.transactions.softDelete(drop);

      final day = await h.transactions.watchDay(october(3)).first;
      expect(day.map((t) => t.id).toList(), [keep]);
    });
  });

  group('TransactionsDao.watchMonth', () {
    test(
      'should_include_both_month_boundaries_and_exclude_neighbours',
      () async {
        final h = useDbHarness();
        final categoryId = await h.categories.insert(
          name: 'Food',
          iconKey: 'restaurant',
          colorValue: 1,
        );

        Future<String> add(LocalDate date) => h.transactions.insert(
          categoryId: categoryId,
          amountMinor: 1,
          currency: 'mmk',
          direction: 'expense',
          date: date,
        );

        final first = await add(LocalDate(2026, 10, 1));
        final mid = await add(LocalDate(2026, 10, 15));
        final last = await add(LocalDate(2026, 10, 31));
        await add(LocalDate(2026, 9, 30));
        await add(LocalDate(2026, 11, 1));

        final month = await h.transactions.watchMonth(octoberMonth).first;
        expect(month.map((t) => t.id).toList(), [first, mid, last]);
      },
    );

    test('should_order_by_day_then_creation', () async {
      final h = useDbHarness();
      final categoryId = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      final later = await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 1,
        currency: 'mmk',
        direction: 'expense',
        date: october(5),
      );
      final earlier = await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 2,
        currency: 'mmk',
        direction: 'expense',
        date: october(2),
      );

      final month = await h.transactions.watchMonth(octoberMonth).first;
      expect(month.map((t) => t.id).toList(), [earlier, later]);
    });
  });

  group('TransactionsDao.watchMonthDailyTotals', () {
    test('should_net_income_against_expense_per_day_in_sql', () async {
      final h = useDbHarness();
      final salary = await h.categories.insert(
        name: 'Salary',
        iconKey: 'payments',
        colorValue: 1,
        kind: 'income',
      );
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 2,
      );

      await h.transactions.insert(
        categoryId: salary,
        amountMinor: 500000,
        currency: 'mmk',
        direction: 'income',
        date: october(3),
      );
      await h.transactions.insert(
        categoryId: food,
        amountMinor: 12000,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      await h.transactions.insert(
        categoryId: food,
        amountMinor: 8000,
        currency: 'mmk',
        direction: 'expense',
        date: october(4),
      );

      final totals = await h.transactions
          .watchMonthDailyTotals(octoberMonth)
          .first;
      final byDay = {for (final t in totals) t.date.value: t.netMinor};

      expect(byDay, {20261003: 488000, 20261004: -8000});
    });

    test('should_omit_days_with_no_activity', () async {
      final h = useDbHarness();
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      await h.transactions.insert(
        categoryId: food,
        amountMinor: 1,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      await h.transactions.insert(
        categoryId: food,
        amountMinor: 2,
        currency: 'mmk',
        direction: 'expense',
        date: october(20),
      );

      final totals = await h.transactions
          .watchMonthDailyTotals(octoberMonth)
          .first;
      expect(
        totals.length,
        2,
        reason: 'the query emits only days that have rows; the UI fills gaps',
      );
      expect(totals.map((t) => t.date.value), [20261003, 20261020]);
    });

    test('should_ignore_a_soft_deleted_row', () async {
      final h = useDbHarness();
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      await h.transactions.insert(
        categoryId: food,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      final deleted = await h.transactions.insert(
        categoryId: food,
        amountMinor: 9999,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      await h.transactions.softDelete(deleted);

      final totals = await h.transactions
          .watchMonthDailyTotals(octoberMonth)
          .first;
      expect(totals.single.netMinor, -100);
    });

    test('should_return_no_rows_for_an_empty_month', () async {
      final h = useDbHarness();
      final totals = await h.transactions
          .watchMonthDailyTotals(octoberMonth)
          .first;
      expect(totals, isEmpty);
    });
  });

  group('TransactionsDao.watchMonthCategoryTotals', () {
    test('should_separate_income_from_expense_for_the_same_category', () async {
      final h = useDbHarness();
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      await h.transactions.insert(
        categoryId: food,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      await h.transactions.insert(
        categoryId: food,
        amountMinor: 200,
        currency: 'mmk',
        direction: 'expense',
        date: october(4),
      );
      await h.transactions.insert(
        categoryId: food,
        amountMinor: 500,
        currency: 'mmk',
        direction: 'income',
        date: october(5),
        note: 'a refund filed under the same category',
      );

      final totals = await h.transactions
          .watchMonthCategoryTotals(octoberMonth)
          .first;
      final byKey = {
        for (final t in totals) '${t.categoryId}:${t.direction}': t.totalMinor,
      };

      expect(byKey, {'$food:expense': 300, '$food:income': 500});
    });

    test('should_exclude_another_month', () async {
      final h = useDbHarness();
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      await h.transactions.insert(
        categoryId: food,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      await h.transactions.insert(
        categoryId: food,
        amountMinor: 777,
        currency: 'mmk',
        direction: 'expense',
        date: LocalDate(2026, 11, 3),
      );

      final totals = await h.transactions
          .watchMonthCategoryTotals(octoberMonth)
          .first;
      expect(totals.single.totalMinor, 100);
    });
  });

  group('TransactionsDao.sumForMonth', () {
    test('should_sum_only_the_requested_direction', () async {
      final h = useDbHarness();
      final salary = await h.categories.insert(
        name: 'Salary',
        iconKey: 'payments',
        colorValue: 1,
        kind: 'income',
      );
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 2,
      );

      await h.transactions.insert(
        categoryId: salary,
        amountMinor: 500000,
        currency: 'mmk',
        direction: 'income',
        date: october(3),
      );
      await h.transactions.insert(
        categoryId: food,
        amountMinor: 20000,
        currency: 'mmk',
        direction: 'expense',
        date: october(4),
      );

      expect(await h.transactions.sumForMonth(octoberMonth, 'income'), 500000);
      expect(await h.transactions.sumForMonth(octoberMonth, 'expense'), 20000);
    });

    test('should_return_zero_for_a_month_with_no_rows', () async {
      final h = useDbHarness();
      expect(await h.transactions.sumForMonth(octoberMonth, 'expense'), 0);
    });

    test('should_exclude_a_soft_deleted_row', () async {
      final h = useDbHarness();
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      await h.transactions.insert(
        categoryId: food,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      final deleted = await h.transactions.insert(
        categoryId: food,
        amountMinor: 9999,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      await h.transactions.softDelete(deleted);

      expect(await h.transactions.sumForMonth(octoberMonth, 'expense'), 100);
    });
  });

  group('TransactionsDao.totalsForDay', () {
    test('should_return_both_directions_unnetted_for_one_day', () async {
      final h = useDbHarness();
      final salary = await h.categories.insert(
        name: 'Salary',
        iconKey: 'payments',
        colorValue: 1,
        kind: 'income',
      );
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 2,
      );

      await h.transactions.insert(
        categoryId: salary,
        amountMinor: 500000,
        currency: 'mmk',
        direction: 'income',
        date: october(3),
      );
      await h.transactions.insert(
        categoryId: food,
        amountMinor: 20000,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );

      final totals = await h.transactions.totalsForDay(october(3));

      expect(totals.incomeMinor, 500000);
      expect(
        totals.expenseMinor,
        20000,
        reason: 'expense stays a positive magnitude, never pre-netted',
      );
    });

    test('should_return_zero_for_both_when_the_day_is_empty', () async {
      final h = useDbHarness();

      final totals = await h.transactions.totalsForDay(october(9));

      expect(
        totals.incomeMinor,
        0,
        reason: 'SUM over an empty filtered set is NULL and must coalesce to 0',
      );
      expect(totals.expenseMinor, 0);
    });

    test('should_scope_the_totals_to_the_requested_day', () async {
      final h = useDbHarness();
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      await h.transactions.insert(
        categoryId: food,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      await h.transactions.insert(
        categoryId: food,
        amountMinor: 700,
        currency: 'mmk',
        direction: 'expense',
        date: october(4),
      );

      expect((await h.transactions.totalsForDay(october(3))).expenseMinor, 100);
      expect((await h.transactions.totalsForDay(october(4))).expenseMinor, 700);
    });

    test('should_exclude_a_soft_deleted_row', () async {
      final h = useDbHarness();
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      await h.transactions.insert(
        categoryId: food,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      final deleted = await h.transactions.insert(
        categoryId: food,
        amountMinor: 9999,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      await h.transactions.softDelete(deleted);

      expect((await h.transactions.totalsForDay(october(3))).expenseMinor, 100);
    });

    test('should_not_leak_into_an_adjacent_month', () async {
      final h = useDbHarness();
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      await h.transactions.insert(
        categoryId: food,
        amountMinor: 500,
        currency: 'mmk',
        direction: 'expense',
        date: LocalDate(2026, 9, 30),
      );

      final totals = await h.transactions.totalsForDay(october(3));

      expect(totals.expenseMinor, 0);
    });
  });

  group('TransactionsDao.updateById', () {
    test('should_change_the_amount_and_keep_amount_unsigned', () async {
      final h = useDbHarness(startMillis: 100);
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );
      final id = await h.transactions.insert(
        categoryId: food,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );
      h.clock.advance(const Duration(seconds: 1));

      await h.transactions.updateById(id, amountMinor: 250, note: 'fixed');

      final row = (await h.transactions.findById(id))!;
      expect(row.amountMinor, 250);
      expect(row.note, 'fixed');
      expect(row.direction, 'expense');
      expect(row.updatedAt, 1100);
      expect(row.createdAt, 100);
    });

    test('should_rewrite_the_date_through_the_converter', () async {
      final h = useDbHarness();
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );
      final id = await h.transactions.insert(
        categoryId: food,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );

      await h.transactions.updateById(id, date: LocalDate(2026, 10, 9));

      expect(await rawValue(h.db, 'transactions', 'date', id), 20261009);
      expect((await h.transactions.findById(id))!.date, LocalDate(2026, 10, 9));
    });
  });

  group('TransactionsDao.softDelete', () {
    test('should_hide_the_row_and_keep_it_on_disk', () async {
      final h = useDbHarness();
      final food = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );
      final id = await h.transactions.insert(
        categoryId: food,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );

      await h.transactions.softDelete(id);

      expect(await h.transactions.findById(id), isNull);
      expect(
        await physicalRowCount(h.db, h.db.transactions),
        1,
        reason: 'deleted rows are retained for sync + undo (ADR #4)',
      );
    });
  });
}
