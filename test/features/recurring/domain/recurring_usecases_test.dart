import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_process_result.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:ledgerly/features/recurring/domain/usecases/delete_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/get_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/process_due_recurring.dart';
import 'package:ledgerly/features/recurring/domain/usecases/save_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/set_recurring_archived.dart';
import 'package:ledgerly/features/recurring/domain/usecases/skip_recurring_occurrence.dart';
import 'package:ledgerly/features/recurring/domain/usecases/watch_recurring_transactions.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

class FakeRecurringRepository implements RecurringRepository {
  final Map<String, RecurringTransaction> _items = {};
  final StreamController<List<RecurringTransaction>> _controller =
      StreamController.broadcast();

  void _emit() {
    _controller.add(_items.values.toList());
  }

  @override
  Stream<List<RecurringTransaction>> watchAll({bool includeArchived = false}) {
    return _controller.stream.map((list) {
      return list.where((t) {
        final notDeleted = t.deletedAt == null;
        return includeArchived ? notDeleted : (notDeleted && !t.isArchived);
      }).toList();
    });
  }

  @override
  Future<List<RecurringTransaction>> getAllActive() async {
    return _items.values.where((t) => t.isActive).toList();
  }

  @override
  Future<RecurringTransaction?> getById(String id) async {
    return _items[id];
  }

  @override
  Future<void> save(RecurringTransaction item) async {
    _items[item.id] = item;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    final item = _items[id];
    if (item != null) {
      _items[id] = item.copyWith(deletedAt: 9999);
      _emit();
    }
  }

  @override
  Future<void> setArchived(String id, bool isArchived) async {
    final item = _items[id];
    if (item != null) {
      _items[id] = item.copyWith(isArchived: isArchived);
      _emit();
    }
  }

  @override
  Future<void> skipNextDueDate(String id) async {
    final item = _items[id];
    if (item != null) {
      final next = item.frequency.nextDate(item.nextDueDate);
      _items[id] = item.copyWith(nextDueDate: next);
      _emit();
    }
  }

  @override
  Future<RecurringProcessResult> processDueTransactions({
    LocalDate? targetDate,
  }) async {
    final date = targetDate ?? LocalDate(2026, 10, 15);
    final generated = <Transaction>[];
    final pending = <RecurringTransaction>[];

    for (final item in _items.values.where((t) => t.isActive)) {
      if (item.isDue(date)) {
        if (item.autoAdd) {
          generated.add(
            Transaction(
              id: 'txn-${item.id}',
              categoryId: item.categoryId,
              accountId: item.accountId,
              amount: item.amount,
              direction: item.direction,
              date: item.nextDueDate,
              createdAt: 1000,
              updatedAt: 1000,
            ),
          );
          final next = item.frequency.nextDate(item.nextDueDate);
          _items[item.id] = item.copyWith(
            nextDueDate: next,
            lastGeneratedDate: item.nextDueDate,
          );
        } else {
          pending.add(item);
        }
      }
    }
    _emit();
    return RecurringProcessResult(
      generatedTransactions: generated,
      pendingRecurring: pending,
    );
  }
}

void main() {
  late FakeRecurringRepository repo;
  late WatchRecurringTransactions watchRecurring;
  late GetRecurringTransaction getRecurring;
  late SaveRecurringTransaction saveRecurring;
  late DeleteRecurringTransaction deleteRecurring;
  late SetRecurringArchived setArchived;
  late SkipRecurringOccurrence skipOccurrence;
  late ProcessDueRecurring processDue;

  final sampleItem = RecurringTransaction(
    id: 'rec-rent',
    categoryId: 'cat-housing',
    amount: const Money.minor(400000, CurrencyCode.mmk),
    direction: TransactionDirection.expense,
    frequency: RecurringFrequency.monthly,
    startDate: LocalDate(2026, 10, 1),
    nextDueDate: LocalDate(2026, 10, 1),
    autoAdd: true,
    createdAt: 1000,
    updatedAt: 1000,
  );

  setUp(() {
    repo = FakeRecurringRepository();
    watchRecurring = WatchRecurringTransactions(repo);
    getRecurring = GetRecurringTransaction(repo);
    saveRecurring = SaveRecurringTransaction(repo);
    deleteRecurring = DeleteRecurringTransaction(repo);
    setArchived = SetRecurringArchived(repo);
    skipOccurrence = SkipRecurringOccurrence(repo);
    processDue = ProcessDueRecurring(repo);
  });

  test('Save and Get recurring transaction', () async {
    await saveRecurring(sampleItem);
    final fetched = await getRecurring(sampleItem.id);
    expect(fetched, sampleItem);
  });

  test('Delete soft-deletes item', () async {
    await saveRecurring(sampleItem);
    await deleteRecurring(sampleItem.id);
    final fetched = await getRecurring(sampleItem.id);
    expect(fetched?.deletedAt, isNotNull);
  });

  test('Set archived updates status', () async {
    await saveRecurring(sampleItem);
    await setArchived(id: sampleItem.id, isArchived: true);
    final fetched = await getRecurring(sampleItem.id);
    expect(fetched?.isArchived, isTrue);
  });

  test('Skip occurrence advances nextDueDate', () async {
    await saveRecurring(sampleItem);
    await skipOccurrence(sampleItem.id);
    final fetched = await getRecurring(sampleItem.id);
    expect(fetched?.nextDueDate, LocalDate(2026, 11, 1));
  });

  test('Process due recurring runs scheduler', () async {
    await saveRecurring(sampleItem);
    final result = await processDue(targetDate: LocalDate(2026, 10, 15));
    expect(result.generatedCount, 1);
    expect(result.generatedTransactions.single.categoryId, 'cat-housing');

    final updated = await getRecurring(sampleItem.id);
    expect(updated?.lastGeneratedDate, LocalDate(2026, 10, 1));
    expect(updated?.nextDueDate, LocalDate(2026, 11, 1));
  });

  test('Watch recurring transactions streams list', () async {
    final future = watchRecurring().first;
    await saveRecurring(sampleItem);
    final list = await future;
    expect(list, hasLength(1));
    expect(list.first.id, sampleItem.id);
  });
}
