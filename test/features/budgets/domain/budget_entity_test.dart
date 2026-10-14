import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_status.dart';

void main() {
  group('Budget Entity', () {
    const totalBudget = Budget(
      id: 'b-total',
      amountMinor: 500000,
      currency: CurrencyCode.mmk,
      sortOrder: 0,
      isArchived: false,
      createdAt: 1000,
      updatedAt: 1000,
    );

    const categoryBudget = Budget(
      id: 'b-cat',
      categoryId: 'cat-food',
      periodId: '2026-10',
      amountMinor: 150000,
      currency: CurrencyCode.mmk,
      alertThreshold: 0.75,
      sortOrder: 1,
      isArchived: false,
      createdAt: 1000,
      updatedAt: 1000,
    );

    test('isTotalBudget and isRecurring flags resolve correctly', () {
      expect(totalBudget.isTotalBudget, isTrue);
      expect(totalBudget.isRecurring, isTrue);

      expect(categoryBudget.isTotalBudget, isFalse);
      expect(categoryBudget.isRecurring, isFalse);
    });

    test('isDeleted flag detects non-null deletedAt', () {
      expect(totalBudget.isDeleted, isFalse);
      final deleted = totalBudget.copyWith(deletedAt: 2000);
      expect(deleted.isDeleted, isTrue);
    });
  });

  group('BudgetProgress Entity', () {
    final period = BudgetPeriod(
      start: LocalDate(2026, 10, 1),
      end: LocalDate(2026, 10, 31),
    );

    const budget = Budget(
      id: 'b-1',
      categoryId: 'cat-1',
      amountMinor: 100000,
      currency: CurrencyCode.mmk,
      alertThreshold: 0.8,
      sortOrder: 0,
      isArchived: false,
      createdAt: 1000,
      updatedAt: 1000,
    );

    test('calculates safe status when spent is below alert threshold', () {
      final progress = BudgetProgress(
        budget: budget,
        spentMinor: 50000,
        period: period,
      );

      expect(progress.remainingMinor, 50000);
      expect(progress.spentPercentage, 50.0);
      expect(progress.isNearLimit, isFalse);
      expect(progress.isOverBudget, isFalse);
      expect(progress.status, BudgetStatus.safe);
      expect(progress.dailyRemainingMinor(10), 5000);
    });

    test('calculates warning status when spent reaches alert threshold', () {
      final progress = BudgetProgress(
        budget: budget,
        spentMinor: 85000,
        period: period,
      );

      expect(progress.remainingMinor, 15000);
      expect(progress.spentPercentage, 85.0);
      expect(progress.isNearLimit, isTrue);
      expect(progress.isOverBudget, isFalse);
      expect(progress.status, BudgetStatus.warning);
    });

    test('calculates exceeded status when spent exceeds budget cap', () {
      final progress = BudgetProgress(
        budget: budget,
        spentMinor: 110000,
        period: period,
      );

      expect(progress.remainingMinor, -10000);
      expect(progress.spentPercentage, 110.0);
      expect(progress.isNearLimit, isFalse);
      expect(progress.isOverBudget, isTrue);
      expect(progress.status, BudgetStatus.exceeded);
      expect(progress.dailyRemainingMinor(10), 0);
    });
  });
}
