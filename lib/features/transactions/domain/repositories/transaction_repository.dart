import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';

/// The domain's contract for reading and writing transactions.
///
/// Read side is split into **row reads** (the day list, the period list) and
/// **aggregate reads** (per-day and per-category totals, a period's sums). Both
/// come from SQL rather than a Dart loop over rows: the aggregate is what makes
/// a year of history scrollable (`docs/Architecture.md` §7,
/// `docs/Conventions.md` §3).
///
/// Every fallible method returns `Result<T>` (`docs/Agent.md` §3.4).
abstract interface class TransactionRepository {
  /// Every live transaction on [date], newest write first.
  Stream<Result<List<Transaction>>> watchDay(LocalDate date);

  /// Every live transaction in [period], oldest day first.
  Stream<Result<List<Transaction>>> watchPeriod(BudgetPeriod period);

  /// Backward-compatible delegate for calendar months (startDay 1).
  Stream<Result<List<Transaction>>> watchMonth(LocalDate month);

  /// Net-per-day totals for [period], computed in SQL.
  ///
  /// Emits a row only for days that have transactions — the UI fills the gaps,
  /// which keeps the result proportional to activity rather than to the length
  /// of the period.
  Stream<Result<List<DailyTotal>>> watchPeriodDailyTotals(
    BudgetPeriod period, {
    required CurrencyCode currency,
  });

  /// Backward-compatible delegate for calendar months (startDay 1).
  Stream<Result<List<DailyTotal>>> watchDailyTotals(
    LocalDate month, {
    required CurrencyCode currency,
  });

  /// Per-category totals for [period], computed in SQL.
  Stream<Result<List<CategoryTotal>>> watchPeriodCategoryTotals(
    BudgetPeriod period, {
    required CurrencyCode currency,
  });

  /// Backward-compatible delegate for calendar months (startDay 1).
  Stream<Result<List<CategoryTotal>>> watchCategoryTotals(
    LocalDate month, {
    required CurrencyCode currency,
  });

  /// A period's headline figures, computed in SQL.
  ///
  /// Derived from the aggregates above rather than a third query streaming every
  /// row: the summary card must paint without loading the whole period.
  Stream<Result<PeriodTotal>> watchPeriodTotal(
    BudgetPeriod period, {
    required CurrencyCode currency,
  });

  /// Backward-compatible delegate for calendar months (startDay 1).
  Stream<Result<PeriodTotal>> watchMonthTotal(
    LocalDate month, {
    required CurrencyCode currency,
  });

  /// A single day's headline figures, computed in SQL.
  ///
  /// The calendar's summary card follows the *selected day*, so it needs a
  /// day-scoped aggregate rather than the period one. Re-emits whenever the day's
  /// rows change, so an edit updates the card without an explicit invalidation.
  Stream<Result<DailyTotal>> watchDayTotal(
    LocalDate date, {
    required CurrencyCode currency,
  });

  /// Sum of [direction] movements within [period], in minor units, or 0.
  Future<Result<int>> sumForPeriod(
    BudgetPeriod period,
    TransactionDirection direction,
  );

  /// Backward-compatible delegate for calendar months (startDay 1).
  Future<Result<int>> sumForMonth(
    LocalDate month,
    TransactionDirection direction,
  );

  /// The transaction with [id], or a `NotFoundFailure` when missing or
  /// soft-deleted.
  Future<Result<Transaction>> findById(String id);

  /// Creates a transaction from [draft] and returns it.
  Future<Result<Transaction>> create(TransactionDraft draft);

  /// Applies [draft] to the transaction with [id] and returns the updated row.
  Future<Result<Transaction>> update(String id, TransactionDraft draft);

  /// Soft-deletes [id].
  Future<Result<void>> delete(String id);

  /// Soft-deletes every id in [ids] in one transaction — the undo/tidy path.
  ///
  /// Batched because a "delete everything in this category" action must not
  /// leave a half-deleted month visible if one write fails.
  Future<Result<void>> deleteMany(List<String> ids);

  /// Restores a soft-deleted [id] — the undo affordance
  /// (`docs/Roadmap.md` Phase 1, "haptics, undo").
  Future<Result<void>> restore(String id);

  /// Searches live transactions matching [filter], with [limit] and [offset]
  /// pagination.
  Future<Result<List<Transaction>>> searchTransactions({
    required TransactionFilter filter,
    int limit = 20,
    int offset = 0,
  });
}
