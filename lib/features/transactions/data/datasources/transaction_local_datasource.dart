import 'package:drift/drift.dart' show Value;
import 'package:ledgerly/core/database/app_database.dart' as db;
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/uuid.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/data/mappers/transaction_mapper.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';

/// Reads and writes transactions in the local SQLite database.
///
/// Owns every Drift type, so nothing above it imports `package:drift`
/// (`docs/Architecture.md` §4). Aggregates are computed **in SQL** — the DAO
/// issues `SUM … GROUP BY` and this class only wraps the result rows in domain
/// entities (`docs/Architecture.md` §7).
class TransactionLocalDataSource {
  TransactionLocalDataSource(
    this._database, {
    this.clock = const Clock(),
    this.idGenerator = generateUuid,
  });

  final db.AppDatabase _database;
  final Clock clock;

  /// Injected so a test can assert on a known id
  /// (`docs/Architecture.md` ADR #3: ids are client-generated UUIDv4).
  final String Function() idGenerator;

  /// Every live transaction on [date], newest write first.
  Stream<List<Transaction>> watchDay(LocalDate date) => _database
      .transactionsDao
      .watchDay(date)
      .map(TransactionMapper.toEntities);

  /// Every live transaction in [month], oldest day first.
  Stream<List<Transaction>> watchMonth(LocalDate month) => _database
      .transactionsDao
      .watchMonth(month)
      .map(TransactionMapper.toEntities);

  /// Income and expense per day for [month], from the DAO's SQL aggregate.
  Stream<List<DailyTotal>> watchDailyTotals(
    LocalDate month, {
    required CurrencyCode currency,
  }) => _database.transactionsDao
      .watchMonthDailyTotals(month)
      .map(
        (totals) => totals
            .map(
              (total) => DailyTotal(
                date: total.date,
                incomeMinor: total.incomeMinor,
                expenseMinor: total.expenseMinor,
                currency: currency,
              ),
            )
            .toList(growable: false),
      );

  /// Per-category totals for [month].
  Stream<List<CategoryTotal>> watchCategoryTotals(
    LocalDate month, {
    required CurrencyCode currency,
  }) => _database.transactionsDao
      .watchMonthCategoryTotals(month)
      .map(
        (totals) => totals
            .map((total) {
              final direction =
                  TransactionDirection.tryParse(total.direction) ??
                  TransactionDirection.expense;
              return CategoryTotal(
                categoryId: total.categoryId,
                direction: direction,
                amountMinor: total.totalMinor,
                currency: currency,
              );
            })
            .toList(growable: false),
      );

  /// A month's headline figures, assembled from two SQL sums.
  ///
  /// Two `SUM` queries rather than streaming the month and folding in Dart: the
  /// summary card must paint without loading every row
  /// (`docs/Conventions.md` §3).
  Stream<MonthTotal> watchMonthTotal(
    LocalDate month, {
    required CurrencyCode currency,
  }) async* {
    // Re-read whenever the month's rows change, so the card tracks an edit
    // without a separate invalidation channel.
    yield* _database.transactionsDao
        .watchMonth(month)
        .asyncMap((_) => _readMonthTotal(month, currency))
        .map((total) => total ?? MonthTotal.empty(month, currency));
  }

  /// One day's headline figures, assembled from a single SQL aggregate.
  ///
  /// Re-reads whenever that day's rows change, so the calendar's summary card
  /// tracks an edit without a separate invalidation channel — the same shape as
  /// [watchMonthTotal].
  ///
  /// Always emits a non-null [DailyTotal]: a day with no rows is a renderable
  /// zero, not a missing value (`DailyTotal.empty`).
  Stream<DailyTotal> watchDayTotal(
    LocalDate date, {
    required CurrencyCode currency,
  }) async* {
    yield* _database.transactionsDao.watchDay(date).asyncMap((_) async {
      final totals = await _database.transactionsDao.totalsForDay(date);
      return DailyTotal(
        date: date,
        incomeMinor: totals.incomeMinor,
        expenseMinor: totals.expenseMinor,
        currency: currency,
      );
    });
  }

  /// The transaction with [id], or null when missing or soft-deleted.
  Future<Transaction?> findById(String id) async {
    final row = await _database.transactionsDao.findById(id);
    return row == null ? null : TransactionMapper.toEntity(row);
  }

  /// Inserts [draft] and returns the stored row.
  ///
  /// The insert and read-back share a transaction so a concurrent write cannot
  /// make the read return null for a row just created.
  Future<Transaction> create(TransactionDraft draft) =>
      _database.transaction(() async {
        final id = _generatedId();
        final now = clock.nowUtcMillis();
        await _database.transactionsDao.insert(
          id: id,
          nowUtcMillis: now,
          categoryId: draft.categoryId,
          amountMinor: draft.amount.abs().amountMinor,
          currency: draft.amount.currency.code.toLowerCase(),
          direction: draft.direction.storageValue,
          date: draft.date,
          note: draft.note,
        );
        final row = await _database.transactionsDao.findById(id);
        return TransactionMapper.toEntity(row!);
      });

  /// Applies [draft] to [id] and returns the updated row.
  ///
  /// Throws [TransactionNotFoundException] when the row does not exist; the
  /// repository maps that to a `NotFoundFailure`.
  Future<Transaction> update(String id, TransactionDraft draft) =>
      _database.transaction(() async {
        final now = clock.nowUtcMillis();
        await _database.transactionsDao.updateById(
          id,
          nowUtcMillis: now,
          categoryId: draft.categoryId,
          amountMinor: draft.amount.abs().amountMinor,
          currency: draft.amount.currency.code.toLowerCase(),
          direction: draft.direction.storageValue,
          date: draft.date,
          note: draft.note,
        );
        final row = await _database.transactionsDao.findById(id);
        if (row == null) throw TransactionNotFoundException(id);
        return TransactionMapper.toEntity(row);
      });

  /// Soft-deletes [id].
  Future<void> delete(String id) => _database.transactionsDao.softDelete(id);

  /// Soft-deletes every id in [ids] in one transaction.
  ///
  /// Batched so a multi-delete cannot leave a partially-updated month visible:
  /// either every tombstone lands or none does.
  Future<void> deleteMany(List<String> ids) {
    if (ids.isEmpty) return Future<void>.value();
    return _database.transaction(() async {
      for (final id in ids) {
        await _database.transactionsDao.softDelete(id);
      }
    });
  }

  /// Clears `deletedAt` on [id] — the undo affordance.
  Future<void> restore(String id) {
    final now = clock.nowUtcMillis();
    return (_database.update(
      _database.transactions,
    )..where((t) => t.id.equals(id))).write(
      db.TransactionsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  /// Sum of [direction] movements within [month], in minor units, or 0.
  Future<int> sumForMonth(LocalDate month, TransactionDirection direction) =>
      _database.transactionsDao.sumForMonth(month, direction.storageValue);

  /// Reads both month sums in one round trip and packages them.
  ///
  /// Returns null when the month has no rows at all, which lets the caller
  /// substitute a `MonthTotal.empty` and keep "no activity" distinct from
  /// "genuinely zero net".
  Future<MonthTotal?> _readMonthTotal(
    LocalDate month,
    CurrencyCode currency,
  ) async {
    final income = await _database.transactionsDao.sumForMonth(
      month,
      TransactionDirection.income.storageValue,
    );
    final expense = await _database.transactionsDao.sumForMonth(
      month,
      TransactionDirection.expense.storageValue,
    );
    if (income == 0 && expense == 0) return null;
    return MonthTotal(
      month: month.firstDayOfMonth,
      incomeMinor: income,
      expenseMinor: expense,
      currency: currency,
    );
  }

  String _generatedId() {
    final id = idGenerator();
    return id.isEmpty ? generateUuid() : id;
  }
}

/// Thrown when a transaction is expected to exist and does not.
///
/// A data-layer signal: the repository catches it and returns a
/// `NotFoundFailure` so `domain/` never sees an exception
/// (`docs/Architecture.md` §8).
final class TransactionNotFoundException implements Exception {
  const TransactionNotFoundException(this.id);

  /// The id that could not be found.
  final String id;

  @override
  String toString() => 'TransactionNotFoundException($id)';
}
