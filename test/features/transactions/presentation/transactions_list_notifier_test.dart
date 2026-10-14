import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ledgerly/features/transactions/domain/usecases/search_transactions.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transactions_list_notifier.dart';

import '../domain/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repository;
  late ProviderContainer container;

  setUp(() {
    final seed = List<Transaction>.generate(
      25,
      (i) => fakeTransaction(
        id: 'txn-$i',
        note: 'Item $i',
        amountMinor: (i + 1) * 1000,
        direction: i.isEven
            ? TransactionDirection.expense
            : TransactionDirection.income,
        date: LocalDate(2026, 10, (i % 28) + 1),
        createdAt: 1000 + i,
      ),
    );
    repository = FakeTransactionRepository(seed: seed);

    container = ProviderContainer(
      overrides: [
        searchTransactionsProvider.overrideWithValue(
          SearchTransactions(repository),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });

  test(
    'loads initial page with default page size and hasMore is true',
    () async {
      final notifier = container.read(transactionsListProvider.notifier);
      await notifier.loadInitial();

      final state = container.read(transactionsListProvider);
      expect(state.isLoading, isFalse);
      expect(state.items.length, 20);
      expect(state.hasMore, isTrue);
      expect(state.error, isNull);
    },
  );

  test(
    'loadMore appends the remaining items and marks hasMore false',
    () async {
      final notifier = container.read(transactionsListProvider.notifier);
      await notifier.loadInitial();
      await notifier.loadMore();

      final state = container.read(transactionsListProvider);
      expect(state.items.length, 25);
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    },
  );

  test('search updates filter and fetches matching items', () async {
    final notifier = container.read(transactionsListProvider.notifier);
    notifier.search('Item 3');
    await notifier.loadInitial();

    final state = container.read(transactionsListProvider);
    expect(state.filter.searchQuery, 'Item 3');
    expect(state.items.length, 1);
    expect(state.items.first.note, 'Item 3');
  });

  test(
    'applyFilter updates direction filter and fetches only matching items',
    () async {
      final notifier = container.read(transactionsListProvider.notifier);
      notifier.applyFilter(
        const TransactionFilter(direction: TransactionDirection.income),
      );
      await notifier.loadInitial();

      final state = container.read(transactionsListProvider);
      expect(state.filter.direction, TransactionDirection.income);
      expect(state.items.every((t) => t.isIncome), isTrue);
    },
  );

  test('clearFilter resets filter back to empty', () async {
    final notifier = container.read(transactionsListProvider.notifier);
    notifier.applyFilter(
      const TransactionFilter(direction: TransactionDirection.expense),
    );
    await notifier.loadInitial();
    expect(container.read(transactionsListProvider).filter.isActive, isTrue);

    notifier.clearFilter();
    await notifier.loadInitial();
    expect(container.read(transactionsListProvider).filter.isEmpty, isTrue);
    expect(container.read(transactionsListProvider).items.length, 20);
  });

  test('removeLocalItem removes item from state.items', () async {
    final notifier = container.read(transactionsListProvider.notifier);
    await notifier.loadInitial();

    final initialCount = container.read(transactionsListProvider).items.length;
    final firstId = container.read(transactionsListProvider).items.first.id;

    notifier.removeLocalItem(firstId);

    final state = container.read(transactionsListProvider);
    expect(state.items.length, initialCount - 1);
    expect(state.items.any((t) => t.id == firstId), isFalse);
  });

  test(
    'handles repository failure gracefully by setting state.error',
    () async {
      repository.forcedFailure = const StorageFailure('db error');
      final notifier = container.read(transactionsListProvider.notifier);
      await notifier.loadInitial();

      final state = container.read(transactionsListProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    },
  );
}
