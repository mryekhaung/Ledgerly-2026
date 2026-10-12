/// In-memory fakes for the transaction domain tests.
///
/// Hand-written rather than generated with `mocktail` so the tests read as
/// behaviour and so a change to the interface breaks the fake at compile time
/// (`docs/Conventions.md` §6: fakes over mocks).
library;

import 'dart:async';

import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:ledgerly/features/transactions/domain/repositories/transaction_repository.dart';

/// A [TransactionRepository] backed by a `List`, for use-case tests.
class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository({
    List<Transaction> seed = const <Transaction>[],
    CurrencyCode currency = CurrencyCode.mmk,
  }) : _items = List<Transaction>.of(seed),
       _currency = currency;

  final List<Transaction> _items;
  final CurrencyCode _currency;

  /// Every draft passed to [create], in order.
  final List<TransactionDraft> createdDrafts = <TransactionDraft>[];

  /// Every id passed to [update], in order.
  final List<String> updatedIds = <String>[];

  /// Every id passed to [restore], in order.
  final List<String> restoredIds = <String>[];

  /// When set, every method returns this failure instead of succeeding.
  Failure? forcedFailure;

  final StreamController<List<Transaction>> _controller =
      StreamController<List<Transaction>>.broadcast();

  /// The current contents, for assertions.
  List<Transaction> get items => List<Transaction>.unmodifiable(_items);

  /// Pushes the current state to subscribers.
  void emit() => _controller.add(List<Transaction>.of(_items));

  /// Releases the stream controller.
  Future<void> dispose() => _controller.close();

  List<Transaction> get _live =>
      _items.where((t) => t.isActive).toList(growable: false);

  @override
  Stream<Result<List<Transaction>>> watchDay(LocalDate date) async* {
    List<Transaction> forDay() =>
        _live.where((t) => t.date == date).toList(growable: false);
    yield Success<List<Transaction>>(forDay());
    yield* _controller.stream.map(
      (list) => Success<List<Transaction>>(
        list.where((t) => t.isActive && t.date == date).toList(growable: false),
      ),
    );
  }

  @override
  Stream<Result<List<Transaction>>> watchMonth(LocalDate month) async* {
    List<Transaction> forMonth() =>
        _live.where((t) => t.date.isSameMonthAs(month)).toList(growable: false);
    yield Success<List<Transaction>>(forMonth());
    yield* _controller.stream.map(
      (list) => Success<List<Transaction>>(
        list
            .where((t) => t.isActive && t.date.isSameMonthAs(month))
            .toList(growable: false),
      ),
    );
  }

  @override
  Stream<Result<List<DailyTotal>>> watchDailyTotals(
    LocalDate month, {
    required CurrencyCode currency,
  }) => watchMonth(month).map(
    (result) => result.map((list) {
      final byDay = <int, DailyTotal>{};
      for (final transaction in list) {
        final existing = byDay[transaction.date.value];
        final income = transaction.isIncome ? transaction.amountMinor : 0;
        final expense = transaction.isExpense ? transaction.amountMinor : 0;
        byDay[transaction.date.value] = DailyTotal(
          date: transaction.date,
          incomeMinor: (existing?.incomeMinor ?? 0) + income,
          expenseMinor: (existing?.expenseMinor ?? 0) + expense,
          currency: currency,
        );
      }
      final totals = byDay.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return totals;
    }),
  );

  @override
  Stream<Result<List<CategoryTotal>>> watchCategoryTotals(
    LocalDate month, {
    required CurrencyCode currency,
  }) => watchMonth(month).map(
    (result) => result.map((list) {
      final byKey = <(String, TransactionDirection), int>{};
      for (final transaction in list) {
        final key = (transaction.categoryId, transaction.direction);
        byKey[key] = (byKey[key] ?? 0) + transaction.amountMinor;
      }
      return byKey.entries
          .map(
            (entry) => CategoryTotal(
              categoryId: entry.key.$1,
              direction: entry.key.$2,
              amountMinor: entry.value,
              currency: currency,
            ),
          )
          .toList(growable: false);
    }),
  );

  @override
  Stream<Result<MonthTotal>> watchMonthTotal(
    LocalDate month, {
    required CurrencyCode currency,
  }) => watchMonth(month).map(
    (result) => result.map((list) {
      var income = 0;
      var expense = 0;
      for (final transaction in list) {
        if (transaction.isIncome) {
          income += transaction.amountMinor;
        } else if (transaction.isExpense) {
          expense += transaction.amountMinor;
        }
      }
      return MonthTotal(
        month: month.firstDayOfMonth,
        incomeMinor: income,
        expenseMinor: expense,
        currency: currency,
      );
    }),
  );

  @override
  Stream<Result<DailyTotal>> watchDayTotal(
    LocalDate date, {
    required CurrencyCode currency,
  }) => watchDay(date).map(
    (result) => result.map((list) {
      var income = 0;
      var expense = 0;
      for (final transaction in list) {
        if (transaction.isIncome) {
          income += transaction.amountMinor;
        } else if (transaction.isExpense) {
          expense += transaction.amountMinor;
        }
      }
      return DailyTotal(
        date: date,
        incomeMinor: income,
        expenseMinor: expense,
        currency: currency,
      );
    }),
  );

  @override
  Future<Result<int>> sumForMonth(
    LocalDate month,
    TransactionDirection direction,
  ) async {
    if (forcedFailure case final failure?) return Err<int>(failure);
    final sum = _live
        .where((t) => t.date.isSameMonthAs(month) && t.direction == direction)
        .fold<int>(0, (total, t) => total + t.amountMinor);
    return Success(sum);
  }

  @override
  Future<Result<Transaction>> findById(String id) async {
    if (forcedFailure case final failure?) return Err<Transaction>(failure);
    final match = _items.where((t) => t.id == id && t.isActive).firstOrNull;
    return match == null
        ? Err<Transaction>(const NotFoundFailure('not found'))
        : Success(match);
  }

  @override
  Future<Result<Transaction>> create(TransactionDraft draft) async {
    createdDrafts.add(draft);
    if (forcedFailure case final failure?) return Err<Transaction>(failure);
    final created = Transaction(
      id: 'generated-${_items.length}',
      categoryId: draft.categoryId,
      amount: draft.amount,
      direction: draft.direction,
      date: draft.date,
      note: draft.note,
      createdAt: 1000,
      updatedAt: 1000,
    );
    _items.add(created);
    emit();
    return Success(created);
  }

  @override
  Future<Result<Transaction>> update(String id, TransactionDraft draft) async {
    updatedIds.add(id);
    if (forcedFailure case final failure?) return Err<Transaction>(failure);
    final index = _items.indexWhere((t) => t.id == id);
    if (index == -1) return Err<Transaction>(const NotFoundFailure('nope'));
    final updated = _items[index].copyWith(
      categoryId: draft.categoryId,
      amount: draft.amount,
      direction: draft.direction,
      date: draft.date,
      note: draft.note,
      updatedAt: 2000,
    );
    _items[index] = updated;
    emit();
    return Success(updated);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (forcedFailure case final failure?) return Err<void>(failure);
    final index = _items.indexWhere((t) => t.id == id);
    if (index == -1) return Err<void>(const NotFoundFailure('nope'));
    _items[index] = _items[index].copyWith(deletedAt: 3000);
    emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteMany(List<String> ids) async {
    if (forcedFailure case final failure?) return Err<void>(failure);
    for (final id in ids) {
      final index = _items.indexWhere((t) => t.id == id);
      if (index != -1) _items[index] = _items[index].copyWith(deletedAt: 3000);
    }
    emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> restore(String id) async {
    restoredIds.add(id);
    if (forcedFailure case final failure?) return Err<void>(failure);
    final index = _items.indexWhere((t) => t.id == id);
    if (index == -1) return Err<void>(const NotFoundFailure('nope'));
    _items[index] = _items[index].copyWith(
      clearDeletedAt: true,
      updatedAt: 3100,
    );
    emit();
    return const Success<void>(null);
  }

  /// The currency this fake's aggregates are denominated in.
  CurrencyCode get currency => _currency;
}

/// Builds a [Transaction] with sensible defaults, so a test states only the
/// field it cares about.
Transaction fakeTransaction({
  String id = 'txn-1',
  String categoryId = 'cat-food',
  int amountMinor = 1000,
  CurrencyCode currency = CurrencyCode.mmk,
  TransactionDirection direction = TransactionDirection.expense,
  LocalDate? date,
  String? note,
  int createdAt = 1000,
  int updatedAt = 1000,
  int? deletedAt,
}) => Transaction(
  id: id,
  categoryId: categoryId,
  amount: Money.minor(amountMinor, currency),
  direction: direction,
  date: date ?? LocalDate(2026, 10, 3),
  note: note,
  createdAt: createdAt,
  updatedAt: updatedAt,
  deletedAt: deletedAt,
);
