import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ledgerly/features/transactions/domain/usecases/search_transactions.dart';

import 'fake_transaction_repository.dart';

void main() {
  group('TransactionFilter', () {
    test('empty filter should not be active', () {
      const filter = TransactionFilter.empty();
      expect(filter.isActive, isFalse);
      expect(filter.isEmpty, isTrue);
      expect(filter.searchQuery, isNull);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
      expect(filter.categoryId, isNull);
      expect(filter.direction, isNull);
      expect(filter.minAmountMinor, isNull);
      expect(filter.maxAmountMinor, isNull);
    });

    test('setting any field makes filter active', () {
      expect(const TransactionFilter(searchQuery: 'tea').isActive, isTrue);
      expect(
        TransactionFilter(startDate: LocalDate(2026, 10, 1)).isActive,
        isTrue,
      );
      expect(
        TransactionFilter(endDate: LocalDate(2026, 10, 31)).isActive,
        isTrue,
      );
      expect(const TransactionFilter(categoryId: 'cat-1').isActive, isTrue);
      expect(
        const TransactionFilter(direction: TransactionDirection.income)
            .isActive,
        isTrue,
      );
      expect(const TransactionFilter(minAmountMinor: 100).isActive, isTrue);
      expect(const TransactionFilter(maxAmountMinor: 5000).isActive, isTrue);
    });

    test('blank whitespace search query does not make filter active', () {
      const filter = TransactionFilter(searchQuery: '   ');
      expect(filter.isActive, isFalse);
      expect(filter.isEmpty, isTrue);
    });

    test('copyWith updates fields and clears correctly', () {
      final initial = TransactionFilter(
        searchQuery: 'coffee',
        startDate: LocalDate(2026, 10, 1),
        endDate: LocalDate(2026, 10, 15),
        categoryId: 'cat-food',
        direction: TransactionDirection.expense,
        minAmountMinor: 500,
        maxAmountMinor: 2000,
      );

      final updated = initial.copyWith(
        searchQuery: 'tea',
        clearStartDate: true,
        clearEndDate: true,
      );

      expect(updated.searchQuery, 'tea');
      expect(updated.startDate, isNull);
      expect(updated.endDate, isNull);
      expect(updated.categoryId, 'cat-food');
      expect(updated.direction, TransactionDirection.expense);
      expect(updated.minAmountMinor, 500);
      expect(updated.maxAmountMinor, 2000);
    });

    test('equality and hashCode work as expected', () {
      final filter1 = TransactionFilter(
        searchQuery: 'lunch',
        startDate: LocalDate(2026, 10, 1),
      );
      final filter2 = TransactionFilter(
        searchQuery: 'lunch',
        startDate: LocalDate(2026, 10, 1),
      );
      const filter3 = TransactionFilter(searchQuery: 'dinner');

      expect(filter1, equals(filter2));
      expect(filter1.hashCode, equals(filter2.hashCode));
      expect(filter1, isNot(equals(filter3)));
    });

    test('clear returns an empty filter', () {
      const filter = TransactionFilter(
        searchQuery: 'test',
        direction: TransactionDirection.income,
      );
      expect(filter.clear(), equals(const TransactionFilter.empty()));
    });
  });

  group('SearchTransactions UseCase', () {
    late FakeTransactionRepository repository;
    late SearchTransactions useCase;

    setUp(() {
      repository = FakeTransactionRepository(
        seed: <Transaction>[
          fakeTransaction(
            id: 'txn-1',
            categoryId: 'cat-food',
            amountMinor: 1500,
            direction: TransactionDirection.expense,
            date: LocalDate(2026, 10, 1),
            note: 'Morning coffee',
            createdAt: 1000,
          ),
          fakeTransaction(
            id: 'txn-2',
            categoryId: 'cat-salary',
            amountMinor: 500000,
            direction: TransactionDirection.income,
            date: LocalDate(2026, 10, 5),
            note: 'Monthly salary',
            createdAt: 2000,
          ),
          fakeTransaction(
            id: 'txn-3',
            categoryId: 'cat-food',
            amountMinor: 3500,
            direction: TransactionDirection.expense,
            date: LocalDate(2026, 10, 10),
            note: 'Dinner with friends',
            createdAt: 3000,
          ),
          fakeTransaction(
            id: 'txn-4',
            categoryId: 'cat-transport',
            amountMinor: 2000,
            direction: TransactionDirection.expense,
            date: LocalDate(2026, 10, 15),
            note: 'Taxi ride',
            createdAt: 4000,
          ),
        ],
      );
      useCase = SearchTransactions(repository);
    });

    tearDown(() => repository.dispose());

    test('returns all transactions when filter is empty, sorted newest first',
        () async {
      final result = await useCase((
        filter: const TransactionFilter.empty(),
        limit: 20,
        offset: 0,
      ));

      expect(result.isSuccess, isTrue);
      final list = (result as Success<List<Transaction>>).value;
      expect(list.length, 4);
      // Sorted by date descending (15th, 10th, 5th, 1st)
      expect(list[0].id, 'txn-4');
      expect(list[1].id, 'txn-3');
      expect(list[2].id, 'txn-2');
      expect(list[3].id, 'txn-1');
    });

    test('filters by search query matching note', () async {
      final result = await useCase((
        filter: const TransactionFilter(searchQuery: 'coffee'),
        limit: 20,
        offset: 0,
      ));

      final list = (result as Success<List<Transaction>>).value;
      expect(list.length, 1);
      expect(list.first.id, 'txn-1');
    });

    test('filters by search query matching category', () async {
      final result = await useCase((
        filter: const TransactionFilter(searchQuery: 'salary'),
        limit: 20,
        offset: 0,
      ));

      final list = (result as Success<List<Transaction>>).value;
      expect(list.length, 1);
      expect(list.first.id, 'txn-2');
    });

    test('filters by direction', () async {
      final result = await useCase((
        filter: const TransactionFilter(direction: TransactionDirection.income),
        limit: 20,
        offset: 0,
      ));

      final list = (result as Success<List<Transaction>>).value;
      expect(list.length, 1);
      expect(list.first.id, 'txn-2');
    });

    test('filters by date range', () async {
      final result = await useCase((
        filter: TransactionFilter(
          startDate: LocalDate(2026, 10, 5),
          endDate: LocalDate(2026, 10, 10),
        ),
        limit: 20,
        offset: 0,
      ));

      final list = (result as Success<List<Transaction>>).value;
      expect(list.length, 2);
      expect(list.map((t) => t.id), ['txn-3', 'txn-2']);
    });

    test('filters by categoryId', () async {
      final result = await useCase((
        filter: const TransactionFilter(categoryId: 'cat-food'),
        limit: 20,
        offset: 0,
      ));

      final list = (result as Success<List<Transaction>>).value;
      expect(list.length, 2);
      expect(list.map((t) => t.id), ['txn-3', 'txn-1']);
    });

    test('filters by amount range', () async {
      final result = await useCase((
        filter: const TransactionFilter(
          minAmountMinor: 2000,
          maxAmountMinor: 5000,
        ),
        limit: 20,
        offset: 0,
      ));

      final list = (result as Success<List<Transaction>>).value;
      expect(list.length, 2);
      expect(list.map((t) => t.id), ['txn-4', 'txn-3']);
    });

    test('paginates results using limit and offset', () async {
      final page1 = await useCase((
        filter: const TransactionFilter.empty(),
        limit: 2,
        offset: 0,
      ));
      final list1 = (page1 as Success<List<Transaction>>).value;
      expect(list1.length, 2);
      expect(list1.map((t) => t.id), ['txn-4', 'txn-3']);

      final page2 = await useCase((
        filter: const TransactionFilter.empty(),
        limit: 2,
        offset: 2,
      ));
      final list2 = (page2 as Success<List<Transaction>>).value;
      expect(list2.length, 2);
      expect(list2.map((t) => t.id), ['txn-2', 'txn-1']);

      final page3 = await useCase((
        filter: const TransactionFilter.empty(),
        limit: 2,
        offset: 4,
      ));
      final list3 = (page3 as Success<List<Transaction>>).value;
      expect(list3, isEmpty);
    });
  });
}
