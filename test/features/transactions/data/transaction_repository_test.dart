import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/app_database.dart' as db;
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:ledgerly/features/transactions/data/mappers/transaction_mapper.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

import 'transaction_data_harness.dart';

/// Data-layer tests for transactions: a real in-memory Drift database, the real
/// datasource, the real mapper.
///
/// The aggregates are exercised against real SQL rather than a Dart re-impl,
/// because the whole point of doing `SUM … GROUP BY` in the DAO is that Dart
/// never gets to be the source of truth for a total.
void main() {
  late TransactionDataHarness harness;

  setUp(() async {
    harness = TransactionDataHarness.over(
      db.AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(harness.dispose);
    await insertRawCategory(harness.db, id: 'cat-1');
    await insertRawCategory(harness.db, id: 'cat-2', name: 'Salary');
  });

  group('TransactionMapper.toEntity', () {
    test('should_round_trip_every_field', () async {
      await harness.datasource.create(
        txDraft(
          amountMinor: 2500,
          direction: TransactionDirection.income,
          note: 'Payday',
        ),
      );

      final stored = expectSuccess(
        await harness.repository.watchDay(LocalDate(2026, 3, 14)).first,
      ).single;

      expect(stored.id, 'tx-0');
      expect(stored.categoryId, 'cat-1');
      expect(stored.amount, Money.minor(2500, CurrencyCode.mmk));
      expect(stored.direction, TransactionDirection.income);
      expect(stored.date, LocalDate(2026, 3, 14));
      expect(stored.note, 'Payday');
      expect(stored.createdAt, 1000);
      expect(stored.updatedAt, 1000);
      expect(stored.deletedAt, isNull);
      expect(stored.accountId, isNull);
    });

    test('should_throw_when_the_stored_direction_is_unknown', () async {
      // Deliberately stricter than the category mapper. A wrong *kind* on a
      // category is cosmetic; a wrong *direction* flips the sign of the user's
      // money in every total, so guessing is worse than failing loudly.
      await harness.db.customStatement(
        'INSERT INTO transactions '
        '(id, category_id, amount_minor, currency, direction, date, '
        'created_at, updated_at) '
        "VALUES ('x', 'cat-1', 100, 'mmk', 'sideways', 20260314, 1, 1)",
      );

      final result = await harness.repository
          .watchDay(LocalDate(2026, 3, 14))
          .first;

      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('should_throw_when_the_stored_currency_is_unknown', () async {
      await harness.db.customStatement(
        'INSERT INTO transactions '
        '(id, category_id, amount_minor, currency, direction, date, '
        'created_at, updated_at) '
        "VALUES ('x', 'cat-1', 100, 'xyz', 'expense', 20260314, 1, 1)",
      );

      final result = await harness.repository
          .watchDay(LocalDate(2026, 3, 14))
          .first;

      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('should_normalise_the_stored_currency_to_lower_case', () async {
      await harness.db.customStatement(
        'INSERT INTO transactions '
        '(id, category_id, amount_minor, currency, direction, date, '
        'created_at, updated_at) '
        "VALUES ('x', 'cat-1', 100, 'USD', 'expense', 20260314, 1, 1)",
      );

      final stored = expectSuccess(
        await harness.repository.watchDay(LocalDate(2026, 3, 14)).first,
      ).single;

      expect(stored.amount.currency, CurrencyCode.usd);
      expect(stored.amount.amountMinor, 100);
    });
  });

  group('TransactionLocalDataSource writes', () {
    test('should_use_the_injected_id_generator', () async {
      final created = await harness.datasource.create(txDraft());

      expect(created.id, 'tx-0');
    });

    test(
      'should_store_the_magnitude_unsigned_when_the_draft_is_negative',
      () async {
        // The form may hand over a negative amount for a "spent" entry; storage
        // keeps the magnitude and the direction separately (docs/DataModel.md §3).
        final created = await harness.datasource.create(
          txDraft(amountMinor: -500),
        );

        expect(created.amount.amountMinor, 500);
        expect(created.direction, TransactionDirection.expense);

        // Prove it on disk, not just in the returned entity.
        final row = await harness.db
            .customSelect(
              'SELECT amount_minor FROM transactions WHERE id = ?',
              variables: [Variable.withString('tx-0')],
            )
            .getSingle();
        expect(row.read<int>('amount_minor'), 500);
      },
    );

    test('should_persist_the_currency_lower_cased', () async {
      await harness.datasource.create(
        txDraft(amountMinor: 100, currency: CurrencyCode.usd),
      );

      final row = await harness.db
          .customSelect(
            'SELECT currency FROM transactions WHERE id = ?',
            variables: [Variable.withString('tx-0')],
          )
          .getSingle();
      expect(row.read<String>('currency'), 'usd');
    });

    test('should_round_trip_the_date_through_its_packed_form', () async {
      await harness.datasource.create(txDraft(year: 2026, month: 1, day: 5));

      final row = await harness.db
          .customSelect(
            'SELECT date FROM transactions WHERE id = ?',
            variables: [Variable.withString('tx-0')],
          )
          .getSingle();

      // `yyyyMMdd` packed into an int — never a timestamp, so a timezone shift
      // cannot move a transaction to the previous day.
      expect(row.read<int>('date'), 20260105);
    });

    test('should_stamp_created_and_updated_from_the_injected_clock', () async {
      harness.clock.advance(const Duration(milliseconds: 250));
      final created = await harness.datasource.create(txDraft());

      expect(created.createdAt, 1250);
      expect(created.updatedAt, 1250);
    });

    test('should_keep_createdAt_when_updating', () async {
      await harness.datasource.create(txDraft());
      harness.clock.advance(const Duration(milliseconds: 1000));

      final updated = await harness.datasource.update(
        'tx-0',
        txDraft(amountMinor: 999, categoryId: 'cat-2'),
      );

      expect(updated.amount.amountMinor, 999);
      expect(updated.categoryId, 'cat-2');
      expect(updated.createdAt, 1000, reason: 'createdAt is never rewritten');
      expect(updated.updatedAt, 2000);
    });

    test(
      'should_throw_when_updating_a_transaction_that_does_not_exist',
      () async {
        await expectLater(
          harness.datasource.update('missing', txDraft()),
          throwsA(isA<TransactionNotFoundException>()),
        );
      },
    );
  });

  group('TransactionLocalDataSource reads', () {
    test('should_return_only_the_requested_day', () async {
      await harness.datasource.create(txDraft(day: 14));
      await harness.datasource.create(txDraft(day: 15));

      final day = expectSuccess(
        await harness.repository.watchDay(LocalDate(2026, 3, 14)).first,
      );

      expect(day.length, 1);
      expect(day.single.date, LocalDate(2026, 3, 14));
    });

    test('should_exclude_the_month_boundaries_from_each_side', () async {
      // The packed comparison is numeric, so the first and last day of a month
      // are exactly the values most likely to be dropped by an off-by-one.
      await harness.datasource.create(txDraft(month: 2, day: 28));
      await harness.datasource.create(txDraft(month: 3, day: 1));
      await harness.datasource.create(txDraft(month: 3, day: 31));
      await harness.datasource.create(txDraft(month: 4, day: 1));

      final march = expectSuccess(
        await harness.repository.watchMonth(LocalDate(2026, 3, 1)).first,
      );

      expect(march.map((t) => t.date.day).toList(), [
        1,
        31,
      ], reason: 'Feb 28 and Apr 1 must not leak into March');
    });

    test('should_order_a_month_oldest_day_first', () async {
      await harness.datasource.create(txDraft(day: 20));
      await harness.datasource.create(txDraft(day: 2));
      await harness.datasource.create(txDraft(day: 11));

      final month = expectSuccess(
        await harness.repository.watchMonth(LocalDate(2026, 3, 1)).first,
      );

      expect(month.map((t) => t.date.day).toList(), [2, 11, 20]);
    });

    test('should_exclude_soft_deleted_rows_from_both_watches', () async {
      await harness.datasource.create(txDraft(day: 14));
      await harness.datasource.delete('tx-0');

      final day = expectSuccess(
        await harness.repository.watchDay(LocalDate(2026, 3, 14)).first,
      );
      final month = expectSuccess(
        await harness.repository.watchMonth(LocalDate(2026, 3, 1)).first,
      );

      expect(day, isEmpty);
      expect(month, isEmpty);
    });

    test(
      'should_return_null_when_findById_misses_a_soft_deleted_row',
      () async {
        await harness.datasource.create(txDraft());
        await harness.datasource.delete('tx-0');

        expect(await harness.datasource.findById('tx-0'), isNull);
      },
    );
  });

  group('TransactionLocalDataSource.restore', () {
    test('should_clear_deletedAt_so_the_row_reappears', () async {
      await harness.datasource.create(txDraft(day: 14));
      await harness.datasource.delete('tx-0');
      harness.clock.advance(const Duration(milliseconds: 500));

      await harness.datasource.restore('tx-0');

      final day = expectSuccess(
        await harness.repository.watchDay(LocalDate(2026, 3, 14)).first,
      );
      expect(day.length, 1);
      expect(day.single.deletedAt, isNull);
      expect(day.single.updatedAt, 1500, reason: 'a restore is an edit');
    });
  });

  group('TransactionLocalDataSource.deleteMany', () {
    test('should_soft_delete_every_given_id', () async {
      await harness.datasource.create(txDraft(day: 1));
      await harness.datasource.create(txDraft(day: 2));
      await harness.datasource.create(txDraft(day: 3));

      await harness.datasource.deleteMany(['tx-0', 'tx-2']);

      final month = expectSuccess(
        await harness.repository.watchMonth(LocalDate(2026, 3, 1)).first,
      );
      expect(month.map((t) => t.id).toList(), ['tx-1']);
    });

    test('should_no_op_on_an_empty_list', () async {
      // Must not open a transaction or touch the clock — a batch delete of
      // nothing is not a write.
      await harness.datasource.create(txDraft());
      harness.clock.advance(const Duration(milliseconds: 500));

      await harness.datasource.deleteMany(const []);

      final day = expectSuccess(
        await harness.repository.watchDay(LocalDate(2026, 3, 14)).first,
      );
      expect(day.single.updatedAt, 1000);
    });
  });

  group('TransactionLocalDataSource aggregates', () {
    test(
      'should_return_both_directions_separately_for_a_break_even_day',
      () async {
        // The bug this pins: deriving the sides from a signed net would report
        // 100 in / 100 out as "no activity" and blank the calendar capsule.
        await harness.datasource.create(
          txDraft(amountMinor: 100, direction: TransactionDirection.income),
        );
        await harness.datasource.create(
          txDraft(amountMinor: 100, direction: TransactionDirection.expense),
        );

        final totals = expectSuccess(
          await harness.repository
              .watchDailyTotals(
                LocalDate(2026, 3, 1),
                currency: CurrencyCode.mmk,
              )
              .first,
        );

        final day = totals.single;
        expect(day.incomeMinor, 100);
        expect(day.expenseMinor, 100);
        expect(day.netMinor, 0);
        expect(
          day.hasActivity,
          isTrue,
          reason: 'a break-even day is still a day with activity',
        );
      },
    );

    test('should_omit_days_without_transactions', () async {
      await harness.datasource.create(txDraft(day: 3));
      await harness.datasource.create(txDraft(day: 9));

      final totals = expectSuccess(
        await harness.repository
            .watchDailyTotals(LocalDate(2026, 3, 1), currency: CurrencyCode.mmk)
            .first,
      );

      expect(totals.map((t) => t.date.day).toList(), [3, 9]);
    });

    test('should_coalesce_an_all_income_day_to_zero_expense', () async {
      // `SUM` over an empty filtered set is NULL; an uncoalesced null would
      // reach the entity as a crash rather than as 0.
      await harness.datasource.create(
        txDraft(amountMinor: 700, direction: TransactionDirection.income),
      );

      final totals = expectSuccess(
        await harness.repository
            .watchDailyTotals(LocalDate(2026, 3, 1), currency: CurrencyCode.mmk)
            .first,
      );

      expect(totals.single.incomeMinor, 700);
      expect(totals.single.expenseMinor, 0);
    });

    test('should_group_category_totals_by_category_and_direction', () async {
      await harness.datasource.create(
        txDraft(categoryId: 'cat-1', amountMinor: 300),
      );
      await harness.datasource.create(
        txDraft(categoryId: 'cat-1', amountMinor: 200),
      );
      await harness.datasource.create(
        txDraft(
          categoryId: 'cat-2',
          amountMinor: 900,
          direction: TransactionDirection.income,
        ),
      );

      final totals = expectSuccess(
        await harness.repository
            .watchCategoryTotals(
              LocalDate(2026, 3, 1),
              currency: CurrencyCode.mmk,
            )
            .first,
      );

      final byCategory = {for (final total in totals) total.categoryId: total};
      expect(byCategory['cat-1']!.amountMinor, 500, reason: '300 + 200');
      expect(byCategory['cat-1']!.direction, TransactionDirection.expense);
      expect(byCategory['cat-2']!.amountMinor, 900);
      expect(byCategory['cat-2']!.direction, TransactionDirection.income);
    });

    test('should_sum_a_month_by_direction', () async {
      await harness.datasource.create(
        txDraft(amountMinor: 400, direction: TransactionDirection.income),
      );
      await harness.datasource.create(
        txDraft(amountMinor: 250, direction: TransactionDirection.expense),
      );
      await harness.datasource.create(
        txDraft(amountMinor: 100, direction: TransactionDirection.expense),
      );

      final income = expectSuccess(
        await harness.repository.sumForMonth(
          LocalDate(2026, 3, 1),
          TransactionDirection.income,
        ),
      );
      final expense = expectSuccess(
        await harness.repository.sumForMonth(
          LocalDate(2026, 3, 1),
          TransactionDirection.expense,
        ),
      );

      expect(income, 400);
      expect(expense, 350);
    });

    test('should_build_a_month_total_from_both_sums', () async {
      await harness.datasource.create(
        txDraft(amountMinor: 400, direction: TransactionDirection.income),
      );
      await harness.datasource.create(
        txDraft(amountMinor: 250, direction: TransactionDirection.expense),
      );

      final total = expectSuccess(
        await harness.repository
            .watchMonthTotal(LocalDate(2026, 3, 1), currency: CurrencyCode.mmk)
            .first,
      );

      expect(total.incomeMinor, 400);
      expect(total.expenseMinor, 250);
      expect(total.netMinor, 150);
      expect(total.month, LocalDate(2026, 3, 1));
    });

    test('should_report_an_empty_month_as_a_zero_total', () async {
      // "No transactions" must be a renderable fact, not a null the summary card
      // has to unwrap — which is why the datasource substitutes MonthTotal.empty.
      final total = expectSuccess(
        await harness.repository
            .watchMonthTotal(LocalDate(2026, 3, 1), currency: CurrencyCode.mmk)
            .first,
      );

      expect(total.isEmpty, isTrue);
      expect(total.month, LocalDate(2026, 3, 1));
    });
  });

  group('TransactionRepositoryImpl failure mapping', () {
    test('should_return_not_found_when_reading_a_missing_row', () async {
      final result = await harness.repository.findById('missing');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('should_return_not_found_when_updating_a_missing_row', () async {
      final result = await harness.repository.update('missing', txDraft());

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('should_map_a_storage_error_when_the_database_is_closed', () async {
      // Closing the connection is the cheapest way to provoke a real engine
      // error and prove the guard contains it (docs/Agent.md §3.4).
      await harness.db.close();

      final result = await harness.repository.sumForMonth(
        LocalDate(2026, 3, 1),
        TransactionDirection.expense,
      );

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('TransactionMapper companion invariants', () {
    test('should_keep_the_currency_when_normalising_the_sign', () {
      // Guards `Money.abs()` in the mapper against a later "optimisation" to
      // `int.abs()`, which would drop the currency and let a USD row be written
      // as MMK.
      final companion = TransactionMapper.toInsertCompanion(
        id: 'tx-0',
        draft: txDraft(amountMinor: -500, currency: CurrencyCode.usd),
        nowUtcMillis: 1,
      );

      expect(companion.amountMinor.value, 500);
      expect(companion.currency.value, 'usd');
    });

    test('should_materialise_every_editable_field_when_updating', () {
      // An absent field would silently retain a value the user just cleared —
      // most visibly the note, which the form can blank.
      final companion = TransactionMapper.toUpdateCompanion(
        draft: txDraft(note: null),
        nowUtcMillis: 500,
      );

      expect(companion.categoryId.present, isTrue);
      expect(companion.amountMinor.present, isTrue);
      expect(companion.currency.present, isTrue);
      expect(companion.direction.present, isTrue);
      expect(companion.date.present, isTrue);
      expect(companion.note.present, isTrue);
      expect(companion.updatedAt.present, isTrue);
    });
  });
}
