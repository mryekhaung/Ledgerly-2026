import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/goals/data/datasources/savings_goals_local_datasource.dart';
import 'package:ledgerly/features/goals/data/repositories/savings_goals_repository_impl.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';

void main() {
  late AppDatabase db;
  late SavingsGoalsLocalDataSource dataSource;
  late SavingsGoalsRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = SavingsGoalsLocalDataSourceImpl(db);
    repository = SavingsGoalsRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await db.close();
  });

  final sampleGoal = SavingsGoal(
    id: 'goal-emergency',
    name: 'Emergency Fund',
    targetAmount: const Money.minor(5000000, CurrencyCode.mmk),
    currentAmount: const Money.minor(1000000, CurrencyCode.mmk),
    targetDate: LocalDate(2026, 12, 31),
    iconKey: 'shield',
    colorValue: 0xFF2E7D32,
    notes: '6 months expenses',
    isArchived: false,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  test('saveGoal and getGoal round-trip accurately', () async {
    final saveResult = await repository.saveGoal(sampleGoal);
    expect(saveResult.isSuccess, isTrue);

    final readResult = await repository.getGoal('goal-emergency');
    expect(readResult.isSuccess, isTrue);
    final fetched = readResult.valueOrNull;
    expect(fetched, isNotNull);
    expect(fetched!.name, 'Emergency Fund');
    expect(fetched.targetAmount.amountMinor, 5000000);
    expect(fetched.currentAmount.amountMinor, 1000000);
    expect(fetched.targetDate, LocalDate(2026, 12, 31));
    expect(fetched.iconKey, 'shield');
  });

  test('watchGoals emits active goals by default', () async {
    await repository.saveGoal(sampleGoal);
    final goals = await repository.watchGoals().first;
    expect(goals.length, 1);
    expect(goals.first.id, 'goal-emergency');
  });

  test('addContribution increments current amount', () async {
    await repository.saveGoal(sampleGoal);
    final contribResult = await repository.addContribution(
      goalId: 'goal-emergency',
      amountMinor: 500000,
    );
    expect(contribResult.isSuccess, isTrue);

    final updated = (await repository.getGoal('goal-emergency')).valueOrNull!;
    expect(updated.currentAmount.amountMinor, 1500000);
    expect(updated.progress, 1500000 / 5000000);
  });

  test('withdraw decrements current amount', () async {
    await repository.saveGoal(sampleGoal);
    final withdrawResult = await repository.withdraw(
      goalId: 'goal-emergency',
      amountMinor: 400000,
    );
    expect(withdrawResult.isSuccess, isTrue);

    final updated = (await repository.getGoal('goal-emergency')).valueOrNull!;
    expect(updated.currentAmount.amountMinor, 600000);
  });

  test('setArchived toggles visibility in active stream', () async {
    await repository.saveGoal(sampleGoal);
    await repository.setArchived(id: 'goal-emergency', archived: true);

    final activeGoals = await repository
        .watchGoals(includeArchived: false)
        .first;
    expect(activeGoals, isEmpty);

    final allGoals = await repository.watchGoals(includeArchived: true).first;
    expect(allGoals.length, 1);
    expect(allGoals.first.isArchived, isTrue);
  });

  test('deleteGoal soft-deletes goal from database', () async {
    await repository.saveGoal(sampleGoal);
    await repository.deleteGoal('goal-emergency');

    final fetched = (await repository.getGoal('goal-emergency')).valueOrNull;
    expect(fetched, isNull);

    final allGoals = await repository.watchGoals(includeArchived: true).first;
    expect(allGoals, isEmpty);
  });
}
