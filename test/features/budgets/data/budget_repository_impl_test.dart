import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:ledgerly/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_status.dart';

import '../../../core/database/db_harness.dart';

void main() {
  group('BudgetRepositoryImpl with real SQLite', () {
    late DbHarness harness;
    late BudgetLocalDataSource datasource;
    late BudgetRepositoryImpl repository;
    final period = BudgetPeriod(
      start: LocalDate(2026, 10, 1),
      end: LocalDate(2026, 10, 31),
    );

    setUp(() async {
      harness = useDbHarness();
      datasource = BudgetLocalDataSourceImpl(
        budgetsDao: harness.db.budgetsDao,
        transactionsDao: harness.transactions,
        categoriesDao: harness.categories,
      );
      repository = BudgetRepositoryImpl(datasource);
    });

    const testBudget = Budget(
      id: 'b-total-1',
      categoryId: null, // Total budget
      periodId: '2026-10',
      amountMinor: 50000000, // 500,000 MMK
      currency: CurrencyCode.mmk,
      alertThreshold: 0.8,
      sortOrder: 0,
      isArchived: false,
      createdAt: 1000,
      updatedAt: 1000,
    );

    test('saveBudget inserts, reads, and updates budget', () async {
      final insertRes = await repository.saveBudget(
        budget: testBudget,
        isNew: true,
      );
      expect(insertRes.isSuccess, isTrue);

      final readRes = await repository.getBudget('b-total-1');
      expect(readRes.isSuccess, isTrue);
      expect(readRes.valueOrNull?.id, 'b-total-1');
      expect(readRes.valueOrNull?.amountMinor, 50000000);

      // Update amount
      final updated = testBudget.copyWith(amountMinor: 60000000);
      final updateRes = await repository.saveBudget(
        budget: updated,
        isNew: false,
      );
      expect(updateRes.isSuccess, isTrue);

      final readAgain = await repository.getBudget('b-total-1');
      expect(readAgain.valueOrNull?.amountMinor, 60000000);
    });

    test('watchBudgets emits saved budgets', () async {
      await repository.saveBudget(budget: testBudget, isNew: true);

      final list = await repository.watchBudgets().first;
      expect(list.isSuccess, isTrue);
      expect(list.valueOrNull?.length, 1);
      expect(list.valueOrNull?.first.id, 'b-total-1');
    });

    test('deleteBudget soft deletes budget', () async {
      await repository.saveBudget(budget: testBudget, isNew: true);
      final delRes = await repository.deleteBudget('b-total-1');
      expect(delRes.isSuccess, isTrue);

      final readRes = await repository.getBudget('b-total-1');
      expect(readRes.isErr, isTrue);
      expect(readRes.valueOrNull, isNull);
    });

    test('archiveBudget archives budget', () async {
      await repository.saveBudget(budget: testBudget, isNew: true);
      final archiveRes = await repository.setBudgetArchived('b-total-1', true);
      expect(archiveRes.isSuccess, isTrue);

      final activeList = await repository
          .watchBudgets(includeArchived: false)
          .first;
      expect(activeList.valueOrNull, isEmpty);

      final allList = await repository
          .watchBudgets(includeArchived: true)
          .first;
      expect(allList.valueOrNull?.length, 1);
      expect(allList.valueOrNull?.first.isArchived, isTrue);
    });

    test('watchBudgetProgress calculates spent and status correctly', () async {
      // 1. Create a category
      await harness.categories.insert(
        id: 'cat-food',
        name: 'Food & Drinks',
        iconKey: 'restaurant',
        colorValue: 0xFF22C55E,
        kind: 'expense',
      );

      // 2. Create category budget for 100,000 MMK
      const catBudget = Budget(
        id: 'b-cat-1',
        categoryId: 'cat-food',
        periodId: '2026-10',
        amountMinor: 10000000, // 100,000 MMK
        currency: CurrencyCode.mmk,
        alertThreshold: 0.8,
        sortOrder: 1,
        isArchived: false,
        createdAt: 1000,
        updatedAt: 1000,
      );
      await repository.saveBudget(budget: catBudget, isNew: true);

      // Also create a total budget
      await repository.saveBudget(budget: testBudget, isNew: true);

      // Check progress before transactions
      var progressList = await repository.getBudgetProgress(period);
      expect(progressList.isSuccess, isTrue);
      expect(progressList.valueOrNull?.length, 2);

      final initialCat = progressList.valueOrNull!.firstWhere(
        (p) => p.budget.isCategoryBudget,
      );
      expect(initialCat.spentMinor, 0);
      expect(initialCat.remainingMinor, 10000000);
      expect(initialCat.status, BudgetStatus.safe);

      // 3. Add expense of 85,000 MMK (85% spent -> warning alert threshold is 80%)
      await harness.transactions.insert(
        id: 'tx-1',
        categoryId: 'cat-food',
        amountMinor: 8500000,
        currency: 'mmk',
        direction: 'expense',
        date: LocalDate(2026, 10, 10),
      );

      progressList = await repository.getBudgetProgress(period);
      final warningCat = progressList.valueOrNull!.firstWhere(
        (p) => p.budget.isCategoryBudget,
      );
      expect(warningCat.spentMinor, 8500000);
      expect(warningCat.remainingMinor, 1500000);
      expect(warningCat.status, BudgetStatus.warning);

      // 4. Add expense of 20,000 MMK (Total 105,000 MMK -> exceeded)
      await harness.transactions.insert(
        id: 'tx-2',
        categoryId: 'cat-food',
        amountMinor: 2000000,
        currency: 'mmk',
        direction: 'expense',
        date: LocalDate(2026, 10, 12),
      );

      progressList = await repository.getBudgetProgress(period);
      final exceededCat = progressList.valueOrNull!.firstWhere(
        (p) => p.budget.isCategoryBudget,
      );
      expect(exceededCat.spentMinor, 10500000);
      expect(exceededCat.remainingMinor, -500000);
      expect(exceededCat.status, BudgetStatus.exceeded);
      expect(exceededCat.isOverBudget, isTrue);

      // Total budget progress check
      final totalProgress = progressList.valueOrNull!.firstWhere(
        (p) => p.budget.isTotalBudget,
      );
      expect(totalProgress.spentMinor, 10500000);
      expect(totalProgress.remainingMinor, 39500000);
      expect(totalProgress.status, BudgetStatus.safe);
    });
  });
}
