import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';

/// Pure conversion between Drift [SavingsGoalRow] and domain [SavingsGoal].
class SavingsGoalMapper {
  const SavingsGoalMapper();

  SavingsGoal toDomain(SavingsGoalRow row) {
    final currency = CurrencyCode.tryParse(row.currency) ?? CurrencyCode.mmk;
    return SavingsGoal(
      id: row.id,
      name: row.name,
      targetAmount: Money.minor(row.targetAmountMinor, currency),
      currentAmount: Money.minor(row.currentAmountMinor, currency),
      targetDate: row.targetDate,
      accountId: row.accountId,
      iconKey: row.iconKey,
      colorValue: row.colorValue,
      notes: row.notes,
      isArchived: row.isArchived,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
    );
  }

  SavingsGoalsCompanion toCompanion(SavingsGoal goal) {
    return SavingsGoalsCompanion(
      id: Value(goal.id),
      name: Value(goal.name),
      targetAmountMinor: Value(goal.targetAmount.amountMinor),
      currentAmountMinor: Value(goal.currentAmount.amountMinor),
      currency: Value(goal.targetAmount.currency.name),
      targetDate: Value(goal.targetDate),
      accountId: Value(goal.accountId),
      iconKey: Value(goal.iconKey),
      colorValue: Value(goal.colorValue),
      notes: Value(goal.notes),
      isArchived: Value(goal.isArchived),
      createdAt: Value(goal.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(goal.updatedAt.millisecondsSinceEpoch),
    );
  }
}
