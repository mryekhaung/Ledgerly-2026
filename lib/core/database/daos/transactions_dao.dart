import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/tables/transactions.dart';
import 'package:ledgerly/core/database/uuid.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/period/period_calculator.dart';
import 'package:ledgerly/core/utils/local_date.dart';

part 'transactions_dao.g.dart';

/// A per-day aggregate **row**: what `GROUP BY date` came back with.
///
/// Named `*Row`, not `DailyTotal`, because the domain owns the `DailyTotal`
/// contract (`features/transactions/domain/entities/transaction_totals.dart`).
/// Two types with one name in the same dependency graph is a collision waiting
/// to happen — and the DAO lives in `core/`, which the domain must not be
/// defined by.
class DailyTotalRow {
  const DailyTotalRow({
    required this.date,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final LocalDate date;

  /// Money in that day, as a positive magnitude.
  final int incomeMinor;

  /// Money out that day, as a positive magnitude.
  ///
  /// Kept separate from [incomeMinor] rather than pre-netted: a day with 100 in
  /// and 100 out is not "no activity" to someone reading the calendar, and
  /// collapsing it to 0 would make the capsule indistinguishable from an empty
  /// day.
  final int expenseMinor;

  /// Income minus expense. Signed — negative means net spending.
  int get netMinor => incomeMinor - expenseMinor;
}

/// A per-category aggregate **row**: what `GROUP BY category_id, direction`
/// came back with.
///
/// `direction` is the raw stored string, not an enum — converting it is the
/// mapper's job, and `core/` does not depend on a feature's domain types.
class CategoryTotalRow {
  const CategoryTotalRow({
    required this.categoryId,
    required this.direction,
    required this.totalMinor,
  });

  final String categoryId;
  final String direction;
  final int totalMinor;
}

/// Data access for [Transactions]. Spec: `docs/DataModel.md` §3.
///
/// Aggregates are computed **in SQL** (`docs/Architecture.md` §7) — a Dart loop
/// over every row of the month would not scale to a year of history, and would
/// duplicate logic that `SUM … GROUP BY` already gets right.
///
/// **Naming note:** the id-based write is `updateById`, not `update`.
/// `DatabaseAccessor` already declares `update<Tbl, R>(TableInfo<Tbl, R>)`, so an
/// incompatible `update(String id, …)` is a compile error rather than an
/// overload (`drift/src/runtime/api/connection_user.dart`).
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db, {this.clock = const Clock()});

  final Clock clock;

  /// Every live transaction on [date], newest write first.
  Stream<List<Transaction>> watchDay(LocalDate date) {
    return (select(transactions)
          ..where((t) => t.deletedAt.isNull() & t.date.equalsValue(date))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Every live transaction in [period], oldest day first.
  /// Backs the Calendar page's day list and capsule grid.
  Stream<List<Transaction>> watchPeriod(BudgetPeriod period) {
    final first = period.start.value;
    final last = period.end.value;
    return (select(transactions)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.date.isBiggerOrEqualValue(first) &
                t.date.isSmallerOrEqualValue(last),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.date),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch();
  }

  /// Backward-compatible alias for calendar months (startDay 1).
  Stream<List<Transaction>> watchMonth(LocalDate month) =>
      watchPeriod(PeriodCalculator(1).containing(month));

  /// Income and expense per day for [period], aggregated in SQL.
  ///
  /// Rows come back only for days that have transactions — the UI fills the gaps
  /// rather than the query emitting empty days, which keeps the result set
  /// proportional to activity instead of to the length of the period.
  ///
  /// Both directions are returned separately (not pre-netted) so a
  /// break-even day still renders as active; see [DailyTotalRow].
  Stream<List<DailyTotalRow>> watchPeriodDailyTotals(BudgetPeriod period) {
    final first = period.start.value;
    final last = period.end.value;

    // Annotated rather than inferred. `ArithmeticAggregates.sum` is declared
    // `Expression<DT> sum()` on `Expression<DT extends num>`, so leaving the
    // type open lets the analyzer settle on `num` — and `num` does not fit
    // `DailyTotalRow.incomeMinor`, which is `int` (money is never a `num`; see
    // `docs/Architecture.md` ADR #2). Pinning `Expression<int>` here is what
    // keeps the arithmetic below an `int` subtraction.
    final Expression<int> income = transactions.amountMinor.sum(
      filter: transactions.direction.equals('income'),
    );
    final Expression<int> expense = transactions.amountMinor.sum(
      filter: transactions.direction.equals('expense'),
    );

    final query = selectOnly(transactions)
      ..addColumns([transactions.date, income, expense])
      ..where(
        transactions.deletedAt.isNull() &
            transactions.date.isBiggerOrEqualValue(first) &
            transactions.date.isSmallerOrEqualValue(last),
      )
      ..groupBy([transactions.date]);

    return query.watch().map(
      (rows) => rows.map((row) {
        final packed = row.read(transactions.date)!;
        final date = LocalDate.fromPacked(packed)!;
        return DailyTotalRow(
          date: date,
          // `SUM` over an empty filtered set is NULL, not 0 — coalesce here
          // rather than letting a null reach the entity.
          incomeMinor: row.read(income) ?? 0,
          expenseMinor: row.read(expense) ?? 0,
        );
      }).toList(),
    );
  }

  /// Backward-compatible alias for calendar months (startDay 1).
  Stream<List<DailyTotalRow>> watchMonthDailyTotals(LocalDate month) =>
      watchPeriodDailyTotals(PeriodCalculator(1).containing(month));

  /// Totals per category for [period], for the summary card / donut.
  Stream<List<CategoryTotalRow>> watchPeriodCategoryTotals(
    BudgetPeriod period,
  ) {
    final first = period.start.value;
    final last = period.end.value;

    // Annotated, as in `watchPeriodDailyTotals` — see the comment there.
    final Expression<int> total = transactions.amountMinor.sum();

    final query = selectOnly(transactions)
      ..addColumns([transactions.categoryId, transactions.direction, total])
      ..where(
        transactions.deletedAt.isNull() &
            transactions.date.isBiggerOrEqualValue(first) &
            transactions.date.isSmallerOrEqualValue(last),
      )
      ..groupBy([transactions.categoryId, transactions.direction]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => CategoryTotalRow(
              categoryId: row.read(transactions.categoryId)!,
              direction: row.read(transactions.direction)!,
              totalMinor: row.read(total) ?? 0,
            ),
          )
          .toList(),
    );
  }

  /// Backward-compatible alias for calendar months (startDay 1).
  Stream<List<CategoryTotalRow>> watchMonthCategoryTotals(LocalDate month) =>
      watchPeriodCategoryTotals(PeriodCalculator(1).containing(month));

  /// Sum of [direction] movements within [period], in minor units, or 0.
  ///
  /// Uses `SUM` in SQL rather than `watchPeriod(...).length` plus Dart arithmetic.
  Future<int> sumForPeriod(BudgetPeriod period, String direction) async {
    final Expression<int> total = transactions.amountMinor.sum();
    final query = selectOnly(transactions)
      ..addColumns([total])
      ..where(
        transactions.deletedAt.isNull() &
            transactions.direction.equals(direction) &
            transactions.date.isBiggerOrEqualValue(period.start.value) &
            transactions.date.isSmallerOrEqualValue(period.end.value),
      );
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  /// Backward-compatible alias for calendar months (startDay 1).
  Future<int> sumForMonth(LocalDate month, String direction) =>
      sumForPeriod(PeriodCalculator(1).containing(month), direction);

  /// Income and expense for a single [date], in minor units, or 0 each.
  ///
  /// One `SUM(… FILTER …)` round trip rather than reusing
  /// [watchMonthDailyTotals] and picking a row out in Dart: the summary card
  /// changes every time the user taps a day, and filtering a whole month's
  /// aggregate to throw all but one row away is wasted work that grows with the
  /// month's activity.
  ///
  /// Returns both directions **un-netted and unsigned**, matching
  /// [DailyTotalRow] — a break-even day must still read as active.
  Future<({int incomeMinor, int expenseMinor})> totalsForDay(
    LocalDate date,
  ) async {
    // Annotated, as everywhere else in this file: leaving `DT` open lets the
    // analyzer settle on `num` (`ArithmeticAggregates<DT extends num>`).
    final Expression<int> income = transactions.amountMinor.sum(
      filter: transactions.direction.equals('income'),
    );
    final Expression<int> expense = transactions.amountMinor.sum(
      filter: transactions.direction.equals('expense'),
    );

    final query = selectOnly(transactions)
      ..addColumns([income, expense])
      ..where(
        transactions.deletedAt.isNull() & transactions.date.equalsValue(date),
      );

    final row = await query.getSingle();
    // `SUM` over an empty set is NULL, not 0 — coalesce before it reaches the
    // entity, exactly as `watchMonthDailyTotals` does.
    return (
      incomeMinor: row.read(income) ?? 0,
      expenseMinor: row.read(expense) ?? 0,
    );
  }

  Future<Transaction?> findById(String id) {
    return (select(
      transactions,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  /// Inserts a transaction. [amountMinor] must be positive — direction carries
  /// the sign (`docs/DataModel.md` §3); this asserts that rather than trusting
  /// every caller.
  ///
  /// [id] and [nowUtcMillis] are overridable so the data layer owns id
  /// generation and the clock; a test then asserts on a known id and timestamp
  /// without reaching around the DAO with raw SQL.
  Future<String> insert({
    required String categoryId,
    required int amountMinor,
    required String currency,
    required String direction,
    required LocalDate date,
    String? accountId,
    String? note,
    String? id,
    int? nowUtcMillis,
  }) async {
    assert(
      amountMinor >= 0,
      'amountMinor must be non-negative; direction carries the sign',
    );
    final newId = id ?? generateUuid();
    final now = nowUtcMillis ?? clock.nowUtcMillis();
    await into(transactions).insert(
      TransactionsCompanion.insert(
        id: Value(newId),
        categoryId: categoryId,
        amountMinor: amountMinor,
        currency: currency,
        direction: direction,
        date: date,
        accountId: Value(accountId),
        note: Value(note),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return newId;
  }

  /// Updates the editable fields of [id]. See the class doc for the `updateById`
  /// name.
  Future<void> updateById(
    String id, {
    String? categoryId,
    int? amountMinor,
    String? currency,
    String? direction,
    LocalDate? date,
    String? note,
    int? nowUtcMillis,
  }) {
    assert(
      amountMinor == null || amountMinor >= 0,
      'amountMinor must be non-negative; direction carries the sign',
    );
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        categoryId: categoryId == null
            ? const Value.absent()
            : Value(categoryId),
        amountMinor: amountMinor == null
            ? const Value.absent()
            : Value(amountMinor),
        currency: currency == null ? const Value.absent() : Value(currency),
        direction: direction == null ? const Value.absent() : Value(direction),
        date: date == null ? const Value.absent() : Value(date),
        note: note == null ? const Value.absent() : Value(note),
        updatedAt: Value(nowUtcMillis ?? clock.nowUtcMillis()),
      ),
    );
  }

  /// Soft-deletes [id] — no `DELETE` statement is issued (`ADR #4`).
  Future<void> softDelete(String id) {
    final now = clock.nowUtcMillis();
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Searches live transactions matching the given filter criteria with pagination.
  Future<List<Transaction>> searchTransactions({
    String? searchQuery,
    LocalDate? startDate,
    LocalDate? endDate,
    String? categoryId,
    String? direction,
    int? minAmountMinor,
    int? maxAmountMinor,
    int limit = 20,
    int offset = 0,
  }) async {
    List<String>? matchingCategoryIds;
    final queryText = searchQuery?.trim();
    if (queryText != null && queryText.isNotEmpty) {
      final matchingCategories =
          await (db.select(db.categories)..where(
                (c) => c.deletedAt.isNull() & c.name.like('%$queryText%'),
              ))
              .get();
      matchingCategoryIds = matchingCategories.map((c) => c.id).toList();
    }

    final query = select(transactions)
      ..where((t) {
        Expression<bool> predicate = t.deletedAt.isNull();

        if (queryText != null && queryText.isNotEmpty) {
          Expression<bool> searchPred = t.note.like('%$queryText%');
          if (matchingCategoryIds != null && matchingCategoryIds.isNotEmpty) {
            searchPred = searchPred | t.categoryId.isIn(matchingCategoryIds);
          }
          predicate = predicate & searchPred;
        }

        if (startDate != null) {
          predicate = predicate & t.date.isBiggerOrEqualValue(startDate.value);
        }
        if (endDate != null) {
          predicate = predicate & t.date.isSmallerOrEqualValue(endDate.value);
        }
        if (categoryId != null) {
          predicate = predicate & t.categoryId.equals(categoryId);
        }
        if (direction != null) {
          predicate = predicate & t.direction.equals(direction);
        }
        if (minAmountMinor != null) {
          predicate =
              predicate & t.amountMinor.isBiggerOrEqualValue(minAmountMinor);
        }
        if (maxAmountMinor != null) {
          predicate =
              predicate & t.amountMinor.isSmallerOrEqualValue(maxAmountMinor);
        }

        return predicate;
      })
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    return query.get();
  }
}
