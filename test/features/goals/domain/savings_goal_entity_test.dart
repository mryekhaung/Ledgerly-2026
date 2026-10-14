import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/validators/savings_goal_validators.dart';

void main() {
  group('SavingsGoal entity', () {
    final now = DateTime(2026, 10, 14);
    final targetDate = LocalDate(2026, 12, 31);
    final today = LocalDate(2026, 10, 14);

    final goal = SavingsGoal(
      id: 'g1',
      name: 'MacBook Pro',
      targetAmount: const Money.minor(300000, CurrencyCode.usd), // $3,000.00
      currentAmount: const Money.minor(150000, CurrencyCode.usd), // $1,500.00
      targetDate: targetDate,
      accountId: 'acc1',
      iconKey: 'laptop',
      colorValue: 0xFF1E88E5,
      notes: 'For development',
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );

    test('progress calculates correct ratio and clamped progress', () {
      expect(goal.progress, 0.5);
      expect(goal.progressRatio, 0.5);
      expect(goal.isCompleted, isFalse);
      expect(goal.remainingAmount.amountMinor, 150000);
    });

    test('isCompleted is true when currentAmount >= targetAmount', () {
      final completed = goal.copyWith(
        currentAmount: const Money.minor(350000, CurrencyCode.usd),
      );
      expect(completed.isCompleted, isTrue);
      expect(completed.progress, 1.0);
      expect(completed.progressRatio, 350000 / 300000);
      expect(completed.remainingAmount.amountMinor, 0);
    });

    test('daysRemaining and isOverdue calculate accurately', () {
      expect(goal.daysRemaining(today), targetDate.daysSince(today));
      expect(goal.isOverdue(today), isFalse);

      final pastDate = LocalDate(2026, 9, 1);
      final overdueGoal = goal.copyWith(targetDate: () => pastDate);
      expect(overdueGoal.isOverdue(today), isTrue);

      // Completed goals are never overdue
      final completedPast = overdueGoal.copyWith(
        currentAmount: const Money.minor(300000, CurrencyCode.usd),
      );
      expect(completedPast.isOverdue(today), isFalse);
    });

    test('equality and hashCode work as expected', () {
      final identicalGoal = goal.copyWith();
      expect(identicalGoal, equals(goal));
      expect(identicalGoal.hashCode, equals(goal.hashCode));

      final differentGoal = goal.copyWith(name: 'Mac Studio');
      expect(differentGoal, isNot(equals(goal)));
    });
  });

  group('SavingsGoalValidators', () {
    test('validateName accepts valid names and rejects invalid ones', () {
      expect(SavingsGoalValidators.validateName('Vacation'), isNull);
      expect(SavingsGoalValidators.validateName(''), 'goalNameRequired');
      expect(SavingsGoalValidators.validateName('   '), 'goalNameRequired');
      expect(SavingsGoalValidators.validateName(null), 'goalNameRequired');
      expect(SavingsGoalValidators.validateName('a' * 101), 'goalNameTooLong');
    });

    test('validateTargetAmount requires positive amount', () {
      expect(SavingsGoalValidators.validateTargetAmount(100), isNull);
      expect(
        SavingsGoalValidators.validateTargetAmount(0),
        'goalTargetAmountInvalid',
      );
      expect(
        SavingsGoalValidators.validateTargetAmount(-10),
        'goalTargetAmountInvalid',
      );
      expect(
        SavingsGoalValidators.validateTargetAmount(null),
        'goalTargetAmountInvalid',
      );
    });

    test('validateCurrentAmount rejects negative amounts', () {
      expect(SavingsGoalValidators.validateCurrentAmount(0), isNull);
      expect(SavingsGoalValidators.validateCurrentAmount(500), isNull);
      expect(
        SavingsGoalValidators.validateCurrentAmount(-1),
        'goalCurrentAmountInvalid',
      );
    });

    test('validateContributionAmount requires positive amount', () {
      expect(SavingsGoalValidators.validateContributionAmount(1000), isNull);
      expect(
        SavingsGoalValidators.validateContributionAmount(0),
        'goalContributionAmountInvalid',
      );
    });

    test('validateWithdrawalAmount enforces positive and <= currentAmount', () {
      expect(
        SavingsGoalValidators.validateWithdrawalAmount(
          amountMinor: 500,
          currentAmountMinor: 1000,
        ),
        isNull,
      );
      expect(
        SavingsGoalValidators.validateWithdrawalAmount(
          amountMinor: 1500,
          currentAmountMinor: 1000,
        ),
        'goalWithdrawExceedsBalance',
      );
      expect(
        SavingsGoalValidators.validateWithdrawalAmount(
          amountMinor: 0,
          currentAmountMinor: 1000,
        ),
        'goalWithdrawAmountInvalid',
      );
    });
  });
}
