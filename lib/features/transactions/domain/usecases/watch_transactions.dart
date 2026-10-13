import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:ledgerly/features/transactions/domain/repositories/transaction_repository.dart';

/// Parameters for [WatchDayTransactions].
typedef WatchDayParams = ({LocalDate date});

/// Watches one day's transactions — the selected-day list.
class WatchDayTransactions
    implements StreamUseCase<List<Transaction>, WatchDayParams> {
  const WatchDayTransactions(this._repository);

  final TransactionRepository _repository;

  @override
  Stream<Result<List<Transaction>>> call(WatchDayParams params) =>
      _repository.watchDay(params.date);
}

/// Parameters for [WatchPeriodTransactions].
typedef WatchPeriodParams = ({BudgetPeriod period});

/// Watches a period's transactions — the calendar's day list and capsule grid.
class WatchPeriodTransactions
    implements StreamUseCase<List<Transaction>, WatchPeriodParams> {
  const WatchPeriodTransactions(this._repository);

  final TransactionRepository _repository;

  @override
  Stream<Result<List<Transaction>>> call(WatchPeriodParams params) =>
      _repository.watchPeriod(params.period);
}

/// Parameters for the aggregate watches.
///
/// Carries `currency` because a SQL `SUM` over minor units is meaningless
/// without knowing what those units are — the repository stamps the result, so
/// the UI never has to guess (`docs/DataModel.md` §1: money always travels with
/// its currency).
typedef PeriodAggregateParams = ({BudgetPeriod period, CurrencyCode currency});

/// Watches the period's net-per-day totals, computed in SQL.
class WatchPeriodDailyTotals
    implements StreamUseCase<List<DailyTotal>, PeriodAggregateParams> {
  const WatchPeriodDailyTotals(this._repository);

  final TransactionRepository _repository;

  @override
  Stream<Result<List<DailyTotal>>> call(PeriodAggregateParams params) =>
      _repository.watchPeriodDailyTotals(
        params.period,
        currency: params.currency,
      );
}

/// Watches the period's per-category totals — the donut / top-categories chart.
class WatchPeriodCategoryTotals
    implements StreamUseCase<List<CategoryTotal>, PeriodAggregateParams> {
  const WatchPeriodCategoryTotals(this._repository);

  final TransactionRepository _repository;

  @override
  Stream<Result<List<CategoryTotal>>> call(PeriodAggregateParams params) =>
      _repository.watchPeriodCategoryTotals(
        params.period,
        currency: params.currency,
      );
}

/// Watches the period's headline figures — the summary card.
class WatchPeriodTotal
    implements StreamUseCase<PeriodTotal, PeriodAggregateParams> {
  const WatchPeriodTotal(this._repository);

  final TransactionRepository _repository;

  @override
  Stream<Result<PeriodTotal>> call(PeriodAggregateParams params) =>
      _repository.watchPeriodTotal(params.period, currency: params.currency);
}

/// Parameters for a single day's aggregate.
///
/// Carries `currency` for the same reason [MonthAggregateParams] does: a SQL
/// `SUM` over minor units is meaningless without knowing what those units are.
typedef DayAggregateParams = ({LocalDate date, CurrencyCode currency});

/// Watches one day's headline figures — the calendar summary card.
///
/// Distinct from [WatchMonthTotal] because the card follows the *selected day*:
/// reusing the month total would show a figure the user did not ask for.
class WatchDayTotal implements StreamUseCase<DailyTotal, DayAggregateParams> {
  const WatchDayTotal(this._repository);

  final TransactionRepository _repository;

  @override
  Stream<Result<DailyTotal>> call(DayAggregateParams params) =>
      _repository.watchDayTotal(params.date, currency: params.currency);
}

/// Parameters for [WatchMonthTransactions] (backward compatibility).
typedef WatchMonthParams = ({LocalDate month});

/// Backward-compatible alias for [WatchPeriodTransactions] over calendar months.
class WatchMonthTransactions
    implements StreamUseCase<List<Transaction>, WatchMonthParams> {
  const WatchMonthTransactions(this._repository);

  final TransactionRepository _repository;

  @override
  Stream<Result<List<Transaction>>> call(WatchMonthParams params) =>
      _repository.watchMonth(params.month);
}

/// Parameters for calendar-month aggregate watches (backward compatibility).
typedef MonthAggregateParams = ({LocalDate month, CurrencyCode currency});

/// Backward-compatible alias for [WatchPeriodDailyTotals].
class WatchMonthDailyTotals
    implements StreamUseCase<List<DailyTotal>, MonthAggregateParams> {
  const WatchMonthDailyTotals(this._repository);

  final TransactionRepository _repository;

  @override
  Stream<Result<List<DailyTotal>>> call(MonthAggregateParams params) =>
      _repository.watchDailyTotals(params.month, currency: params.currency);
}

/// Backward-compatible alias for [WatchPeriodCategoryTotals].
class WatchMonthCategoryTotals
    implements StreamUseCase<List<CategoryTotal>, MonthAggregateParams> {
  const WatchMonthCategoryTotals(this._repository);

  final TransactionRepository _repository;

  @override
  Stream<Result<List<CategoryTotal>>> call(MonthAggregateParams params) =>
      _repository.watchCategoryTotals(params.month, currency: params.currency);
}

/// Backward-compatible alias for [WatchPeriodTotal].
class WatchMonthTotal
    implements StreamUseCase<PeriodTotal, MonthAggregateParams> {
  const WatchMonthTotal(this._repository);

  final TransactionRepository _repository;

  @override
  Stream<Result<PeriodTotal>> call(MonthAggregateParams params) =>
      _repository.watchMonthTotal(params.month, currency: params.currency);
}
