import 'package:ledgerly/core/database/result_guard.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:ledgerly/features/transactions/domain/repositories/transaction_repository.dart';

/// The local-first implementation of [TransactionRepository].
///
/// Talks to SQLite only today. The v0.4 sync layer adds a remote datasource and
/// an outbox write on each mutation — this class is the seam, and nothing above
/// it changes (`docs/Architecture.md` §4, ADR #5).
///
/// **Every method returns `Result`; none throws.** The failure paths that matter
/// are a missing row (mapped to `NotFoundFailure`), an unrecognised stored
/// currency/direction (also mapped), and a database error (mapped by
/// [FailureMapper]).
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._local);

  final TransactionLocalDataSource _local;

  @override
  Stream<Result<List<Transaction>>> watchDay(LocalDate date) =>
      guardResultStream(_local.watchDay(date));

  @override
  Stream<Result<List<Transaction>>> watchPeriod(BudgetPeriod period) =>
      guardResultStream(_local.watchPeriod(period));

  @override
  Stream<Result<List<Transaction>>> watchMonth(LocalDate month) =>
      guardResultStream(_local.watchMonth(month));

  @override
  Stream<Result<List<DailyTotal>>> watchPeriodDailyTotals(
    BudgetPeriod period, {
    required CurrencyCode currency,
  }) => guardResultStream(
    _local.watchPeriodDailyTotals(period, currency: currency),
  );

  @override
  Stream<Result<List<DailyTotal>>> watchDailyTotals(
    LocalDate month, {
    required CurrencyCode currency,
  }) => guardResultStream(_local.watchDailyTotals(month, currency: currency));

  @override
  Stream<Result<List<CategoryTotal>>> watchPeriodCategoryTotals(
    BudgetPeriod period, {
    required CurrencyCode currency,
  }) => guardResultStream(
    _local.watchPeriodCategoryTotals(period, currency: currency),
  );

  @override
  Stream<Result<List<CategoryTotal>>> watchCategoryTotals(
    LocalDate month, {
    required CurrencyCode currency,
  }) =>
      guardResultStream(_local.watchCategoryTotals(month, currency: currency));

  @override
  Stream<Result<PeriodTotal>> watchPeriodTotal(
    BudgetPeriod period, {
    required CurrencyCode currency,
  }) => guardResultStream(_local.watchPeriodTotal(period, currency: currency));

  @override
  Stream<Result<PeriodTotal>> watchMonthTotal(
    LocalDate month, {
    required CurrencyCode currency,
  }) => guardResultStream(_local.watchMonthTotal(month, currency: currency));

  @override
  Stream<Result<DailyTotal>> watchDayTotal(
    LocalDate date, {
    required CurrencyCode currency,
  }) => guardResultStream(_local.watchDayTotal(date, currency: currency));

  @override
  Future<Result<int>> sumForPeriod(
    BudgetPeriod period,
    TransactionDirection direction,
  ) => guardResult(() => _local.sumForPeriod(period, direction));

  @override
  Future<Result<int>> sumForMonth(
    LocalDate month,
    TransactionDirection direction,
  ) => guardResult(() => _local.sumForMonth(month, direction));

  @override
  Future<Result<Transaction>> findById(String id) => guardResult(() async {
    final transaction = await _local.findById(id);
    if (transaction == null || !transaction.isActive) {
      throw TransactionNotFoundException(id);
    }
    return transaction;
  }, onError: _notFoundAsFailure);

  @override
  Future<Result<Transaction>> create(TransactionDraft draft) =>
      guardResult(() => _local.create(draft));

  @override
  Future<Result<Transaction>> update(String id, TransactionDraft draft) =>
      guardResult(() => _local.update(id, draft), onError: _notFoundAsFailure);

  @override
  Future<Result<void>> delete(String id) =>
      guardResult(() => _local.delete(id));

  @override
  Future<Result<void>> deleteMany(List<String> ids) =>
      guardResult(() => _local.deleteMany(ids));

  @override
  Future<Result<void>> restore(String id) =>
      guardResult(() => _local.restore(id));

  @override
  Future<Result<List<Transaction>>> searchTransactions({
    required TransactionFilter filter,
    int limit = 20,
    int offset = 0,
  }) => guardResult(
    () => _local.searchTransactions(
      filter: filter,
      limit: limit,
      offset: offset,
    ),
  );

  /// Maps "row is gone" to a domain `NotFoundFailure` and everything else to the
  /// generic storage failure.
  ///
  /// An unrecognised stored currency or direction also becomes a domain-visible
  /// failure rather than a crash — see `TransactionMapper.toEntity` for why this
  /// one refuses to guess (`docs/Architecture.md` §8).
  static Failure _notFoundAsFailure(Object error, StackTrace stackTrace) =>
      error is TransactionNotFoundException
      ? NotFoundFailure(error.toString(), cause: error, stackTrace: stackTrace)
      : FailureMapper.fromStorage(error, stackTrace);
}
