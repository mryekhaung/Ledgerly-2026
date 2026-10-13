import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/period/period_calculator.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/save_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:ledgerly/features/transactions/domain/validators/transaction_validators.dart';

import 'fake_transaction_repository.dart';

/// Use-case tests. Each asserts the decision the use case makes — which
/// repository method, with what arguments — since that is the only reason the
/// class exists.
void main() {
  late FakeTransactionRepository repository;

  setUp(() {
    repository = FakeTransactionRepository(
      seed: <Transaction>[fakeTransaction(id: 'txn-1')],
    );
    addTearDown(repository.dispose);
  });

  group('SaveTransaction', () {
    final validDraft = (
      categoryId: 'cat-food',
      amount: const Money.minor(1500, CurrencyCode.mmk),
      direction: TransactionDirection.expense,
      date: LocalDate(2026, 10, 3),
      note: 'lunch',
    );

    test('should_create_when_id_is_null', () async {
      final result = await SaveTransaction(repository)((
        id: null,
        draft: validDraft,
      ));

      expect(result.isSuccess, isTrue);
      expect(repository.createdDrafts.length, 1);
      expect(repository.updatedIds, isEmpty);
    });

    test('should_update_when_id_is_provided', () async {
      final result = await SaveTransaction(repository)((
        id: 'txn-1',
        draft: validDraft,
      ));

      expect(result.isSuccess, isTrue);
      expect(repository.updatedIds, ['txn-1']);
    });

    test('should_store_the_magnitude_unsigned_when_the_amount_is_negative', () async {
      // The whole schema rests on this: direction carries the sign, so the
      // amount must be stored positive even if a keypad handed back a negative.
      await SaveTransaction(repository)((
        id: null,
        draft: (
          categoryId: 'cat-food',
          amount: const Money.minor(-1500, CurrencyCode.mmk),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 10, 3),
          note: null,
        ),
      ));

      expect(repository.createdDrafts.single.amount.amountMinor, 1500);
      expect(
        repository.createdDrafts.single.direction,
        TransactionDirection.expense,
      );
    });

    test('should_keep_the_currency_when_normalising_the_sign', () async {
      // A bare `int.abs()` would lose the currency; `Money.abs()` must not.
      await SaveTransaction(repository)((
        id: null,
        draft: (
          categoryId: 'cat-food',
          amount: const Money.minor(-1500, CurrencyCode.usd),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 10, 3),
          note: null,
        ),
      ));

      expect(repository.createdDrafts.single.amount.currency, CurrencyCode.usd);
    });

    test('should_trim_the_note_when_storing', () async {
      await SaveTransaction(repository)((
        id: null,
        draft: (
          categoryId: 'cat-food',
          amount: const Money.minor(100, CurrencyCode.mmk),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 10, 3),
          note: '  lunch  ',
        ),
      ));

      expect(repository.createdDrafts.single.note, 'lunch');
    });

    test('should_map_a_blank_note_to_null', () async {
      await SaveTransaction(repository)((
        id: null,
        draft: (
          categoryId: 'cat-food',
          amount: const Money.minor(100, CurrencyCode.mmk),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 10, 3),
          note: '   ',
        ),
      ));

      expect(repository.createdDrafts.single.note, isNull);
    });

    test(
      'should_fail_with_an_amount_field_error_when_amount_is_zero',
      () async {
        final result = await SaveTransaction(repository)((
          id: null,
          draft: (
            categoryId: 'cat-food',
            amount: const Money.minor(0, CurrencyCode.mmk),
            direction: TransactionDirection.expense,
            date: LocalDate(2026, 10, 3),
            note: null,
          ),
        ));

        expect(
          (result.failureOrNull! as ValidationFailure).fieldErrors['amount'],
          TransactionValidators.amountZero,
        );
        expect(repository.createdDrafts, isEmpty);
      },
    );

    test(
      'should_fail_with_a_category_field_error_when_category_is_blank',
      () async {
        final result = await SaveTransaction(repository)((
          id: null,
          draft: (
            categoryId: '',
            amount: const Money.minor(100, CurrencyCode.mmk),
            direction: TransactionDirection.expense,
            date: LocalDate(2026, 10, 3),
            note: null,
          ),
        ));

        expect(
          (result.failureOrNull! as ValidationFailure)
              .fieldErrors['categoryId'],
          TransactionValidators.categoryRequired,
        );
      },
    );

    test(
      'should_fail_with_a_direction_field_error_when_direction_is_transfer',
      () async {
        final result = await SaveTransaction(repository)((
          id: null,
          draft: (
            categoryId: 'cat-food',
            amount: const Money.minor(100, CurrencyCode.mmk),
            direction: TransactionDirection.transfer,
            date: LocalDate(2026, 10, 3),
            note: null,
          ),
        ));

        expect(
          (result.failureOrNull! as ValidationFailure).fieldErrors['direction'],
          TransactionValidators.directionUnsupported,
        );
      },
    );

    test(
      'should_fail_with_a_note_field_error_when_the_note_is_too_long',
      () async {
        final result = await SaveTransaction(repository)((
          id: null,
          draft: (
            categoryId: 'cat-food',
            amount: const Money.minor(100, CurrencyCode.mmk),
            direction: TransactionDirection.expense,
            date: LocalDate(2026, 10, 3),
            note: 'a' * (TransactionValidators.maxNoteLength + 1),
          ),
        ));

        expect(
          (result.failureOrNull! as ValidationFailure).fieldErrors['note'],
          TransactionValidators.noteTooLong,
        );
      },
    );

    test('should_propagate_a_repository_failure_unchanged', () async {
      repository.forcedFailure = const StorageFailure('disk full');

      final result = await SaveTransaction(repository)((
        id: null,
        draft: validDraft,
      ));

      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('should_not_write_when_validation_fails', () async {
      await SaveTransaction(repository)((
        id: null,
        draft: (
          categoryId: '',
          amount: const Money.minor(0, CurrencyCode.mmk),
          direction: TransactionDirection.transfer,
          date: LocalDate(2026, 10, 3),
          note: null,
        ),
      ));

      expect(repository.createdDrafts, isEmpty);
      expect(repository.updatedIds, isEmpty);
    });
  });

  group('GetTransaction', () {
    test('should_return_the_transaction_when_it_is_live', () async {
      final result = await GetTransaction(repository)((id: 'txn-1'));

      expect(result.valueOrNull?.id, 'txn-1');
    });

    test(
      'should_fail_with_not_found_when_the_transaction_is_missing',
      () async {
        final result = await GetTransaction(repository)((id: 'nope'));

        expect(result.failureOrNull, isA<NotFoundFailure>());
      },
    );

    test(
      'should_fail_with_not_found_when_the_transaction_is_soft_deleted',
      () async {
        final softDeleted = FakeTransactionRepository(
          seed: <Transaction>[fakeTransaction(id: 'txn-1', deletedAt: 500)],
        );
        addTearDown(softDeleted.dispose);

        final result = await GetTransaction(softDeleted)((id: 'txn-1'));

        expect(result.failureOrNull, isA<NotFoundFailure>());
      },
    );
  });

  group('DeleteTransaction', () {
    test('should_soft_delete_when_the_transaction_exists', () async {
      final result = await DeleteTransaction(repository)((id: 'txn-1'));

      expect(result.isSuccess, isTrue);
      expect(repository.items.single.deletedAt, isNotNull);
    });
  });

  group('RestoreTransaction', () {
    test('should_clear_the_tombstone_when_asked', () async {
      await DeleteTransaction(repository)((id: 'txn-1'));
      final result = await RestoreTransaction(repository)((id: 'txn-1'));

      expect(result.isSuccess, isTrue);
      expect(repository.restoredIds, ['txn-1']);
      expect(repository.items.single.deletedAt, isNull);
    });
  });

  group('watch use cases', () {
    test('should_delegate_watchDay_with_the_given_date', () async {
      final result = await WatchDayTransactions(repository)((
        date: LocalDate(2026, 10, 3),
      )).first;

      expect(result.valueOrNull?.length, 1);
    });

    test('should_exclude_other_days_when_watching_a_day', () async {
      final otherDay = LocalDate(2026, 10, 4);
      await repository.create((
        categoryId: 'cat-food',
        amount: const Money.minor(500, CurrencyCode.mmk),
        direction: TransactionDirection.expense,
        date: otherDay,
        note: null,
      ));

      final result = await WatchDayTransactions(repository)((
        date: LocalDate(2026, 10, 3),
      )).first;

      expect(result.valueOrNull?.length, 1);
    });

    test('should_delegate_watchMonth_with_only_that_month', () async {
      final result = await WatchMonthTransactions(repository)((
        month: LocalDate(2026, 10, 1),
      )).first;

      expect(result.valueOrNull?.length, 1);
    });

    test('should_exclude_a_neighbouring_month_when_watching_a_month', () async {
      final result = await WatchMonthTransactions(repository)((
        month: LocalDate(2026, 9, 1),
      )).first;

      expect(result.valueOrNull, isEmpty);
    });

    test('should_sum_both_directions_when_watching_daily_totals', () async {
      await repository.create((
        categoryId: 'cat-food',
        amount: const Money.minor(500, CurrencyCode.mmk),
        direction: TransactionDirection.income,
        date: LocalDate(2026, 10, 3),
        note: null,
      ));

      final result = await WatchMonthDailyTotals(repository)((
        month: LocalDate(2026, 10, 1),
        currency: CurrencyCode.mmk,
      )).first;

      final day = result.valueOrNull!.single;
      expect(day.expenseMinor, 1000);
      expect(day.incomeMinor, 500);
    });

    test(
      'should_not_collapse_a_break_even_day_to_zero_when_watching_daily_totals',
      () async {
        // A day with equal in and out is not "no activity" — the capsule must
        // still light up, which is why income and expense are separate fields.
        await repository.create((
          categoryId: 'cat-food',
          amount: const Money.minor(1000, CurrencyCode.mmk),
          direction: TransactionDirection.income,
          date: LocalDate(2026, 10, 3),
          note: null,
        ));

        final result = await WatchMonthDailyTotals(repository)((
          month: LocalDate(2026, 10, 1),
          currency: CurrencyCode.mmk,
        )).first;

        final day = result.valueOrNull!.single;
        expect(day.netMinor, 0);
        expect(day.hasActivity, isTrue);
      },
    );

    test(
      'should_group_per_category_and_direction_when_watching_category_totals',
      () async {
        final result = await WatchMonthCategoryTotals(repository)((
          month: LocalDate(2026, 10, 1),
          currency: CurrencyCode.mmk,
        )).first;

        final totals = result.valueOrNull!;
        expect(totals.length, 1);
        expect(totals.single.categoryId, 'cat-food');
        expect(totals.single.direction, TransactionDirection.expense);
        expect(totals.single.amountMinor, 1000);
      },
    );

    test('should_report_a_month_total_when_watching_month_total', () async {
      final result = await WatchMonthTotal(repository)((
        month: LocalDate(2026, 10, 1),
        currency: CurrencyCode.mmk,
      )).first;

      expect(result.valueOrNull?.expenseMinor, 1000);
      expect(result.valueOrNull?.incomeMinor, 0);
    });

    test(
      'should_report_an_empty_month_total_when_there_is_no_activity',
      () async {
        final result = await WatchMonthTotal(repository)((
          month: LocalDate(2026, 8, 1),
          currency: CurrencyCode.mmk,
        )).first;

        expect(result.valueOrNull?.isEmpty, isTrue);
      },
    );

    test('should_report_a_day_total_when_watching_day_total', () async {
      final result = await WatchDayTotal(repository)((
        date: LocalDate(2026, 10, 3),
        currency: CurrencyCode.mmk,
      )).first;

      expect(result.valueOrNull?.expenseMinor, 1000);
      expect(result.valueOrNull?.incomeMinor, 0);
      expect(result.valueOrNull?.netMinor, -1000);
    });

    test(
      'should_report_a_zero_day_total_when_the_day_has_no_activity',
      () async {
        final result = await WatchDayTotal(repository)((
          date: LocalDate(2026, 10, 9),
          currency: CurrencyCode.mmk,
        )).first;

        expect(result.valueOrNull?.hasActivity, isFalse);
        expect(result.valueOrNull?.netMinor, 0);
      },
    );

    test('should_scope_a_day_total_to_that_day_only', () async {
      await repository.create((
        categoryId: 'cat-food',
        amount: const Money.minor(500, CurrencyCode.mmk),
        direction: TransactionDirection.income,
        date: LocalDate(2026, 10, 4),
        note: null,
      ));

      final third = await WatchDayTotal(repository)((
        date: LocalDate(2026, 10, 3),
        currency: CurrencyCode.mmk,
      )).first;
      final fourth = await WatchDayTotal(repository)((
        date: LocalDate(2026, 10, 4),
        currency: CurrencyCode.mmk,
      )).first;

      // The month total would be identical for both; a day total must not be.
      expect(third.valueOrNull?.incomeMinor, 0);
      expect(fourth.valueOrNull?.incomeMinor, 500);
      expect(fourth.valueOrNull?.expenseMinor, 0);
    });

    test('should_delegate_watchPeriod_with_the_given_period', () async {
      final period = PeriodCalculator(10).containing(LocalDate(2026, 10, 3));
      final result = await WatchPeriodTransactions(repository)((period: period))
          .first;

      expect(result.valueOrNull?.length, 1);
    });

    test(
      'should_delegate_watchPeriodDailyTotals_with_the_given_period',
      () async {
        final period = PeriodCalculator(10).containing(LocalDate(2026, 10, 3));
        final result = await WatchPeriodDailyTotals(repository)((
          period: period,
          currency: CurrencyCode.mmk,
        )).first;

        expect(result.valueOrNull?.length, 1);
      },
    );

    test(
      'should_delegate_watchPeriodCategoryTotals_with_the_given_period',
      () async {
        final period = PeriodCalculator(10).containing(LocalDate(2026, 10, 3));
        final result = await WatchPeriodCategoryTotals(repository)((
          period: period,
          currency: CurrencyCode.mmk,
        )).first;

        expect(result.valueOrNull?.length, 1);
      },
    );

    test('should_delegate_watchPeriodTotal_with_the_given_period', () async {
      final period = PeriodCalculator(10).containing(LocalDate(2026, 10, 3));
      final result = await WatchPeriodTotal(repository)((
        period: period,
        currency: CurrencyCode.mmk,
      )).first;

      expect(result.valueOrNull?.expenseMinor, 1000);
    });
  });

  group('SumForPeriod', () {
    test('should_sum_only_the_requested_direction', () async {
      await repository.create((
        categoryId: 'cat-food',
        amount: const Money.minor(700, CurrencyCode.mmk),
        direction: TransactionDirection.income,
        date: LocalDate(2026, 10, 4),
        note: null,
      ));

      final period = PeriodCalculator(1).containing(LocalDate(2026, 10, 1));
      final expense = await repository.sumForPeriod(
        period,
        TransactionDirection.expense,
      );
      final income = await repository.sumForPeriod(
        period,
        TransactionDirection.income,
      );

      expect(expense, isA<Success<int>>());
      expect((expense as Success<int>).value, 1000);
      expect(income.valueOrNull, 700);
    });
  });

  group('SumForMonth', () {
    test('should_sum_only_the_requested_direction', () async {
      await repository.create((
        categoryId: 'cat-food',
        amount: const Money.minor(700, CurrencyCode.mmk),
        direction: TransactionDirection.income,
        date: LocalDate(2026, 10, 4),
        note: null,
      ));

      final expense = await repository.sumForMonth(
        LocalDate(2026, 10, 1),
        TransactionDirection.expense,
      );
      final income = await repository.sumForMonth(
        LocalDate(2026, 10, 1),
        TransactionDirection.income,
      );

      expect(expense, isA<Success<int>>());
      expect((expense as Success<int>).value, 1000);
      expect(income.valueOrNull, 700);
    });

    test('should_exclude_soft_deleted_rows', () async {
      await repository.delete('txn-1');

      final result = await repository.sumForMonth(
        LocalDate(2026, 10, 1),
        TransactionDirection.expense,
      );

      expect(result.valueOrNull, 0);
    });
  });
}
