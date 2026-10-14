import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/add_goal_contribution.dart';
import 'package:ledgerly/features/goals/domain/usecases/delete_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/get_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/save_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/set_goal_archived.dart';
import 'package:ledgerly/features/goals/domain/usecases/watch_savings_goals.dart';
import 'package:ledgerly/features/goals/domain/usecases/withdraw_from_goal.dart';
import 'package:ledgerly/features/goals/presentation/providers/goals_providers.dart';

import '../domain/savings_goal_usecases_test.dart';

void main() {
  late FakeSavingsGoalsRepository repo;
  late ProviderContainer container;

  final sampleGoal = SavingsGoal(
    id: 'goal-1',
    name: 'Vacation to Japan',
    targetAmount: const Money.minor(3000000, CurrencyCode.mmk),
    currentAmount: const Money.minor(1000000, CurrencyCode.mmk),
    targetDate: LocalDate(2026, 12, 1),
    iconKey: 'flight',
    colorValue: 0xFF1976D2,
    notes: 'Winter holiday',
    isArchived: false,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  setUp(() {
    repo = FakeSavingsGoalsRepository();
    container = ProviderContainer(
      overrides: [
        saveSavingsGoalProvider.overrideWithValue(SaveSavingsGoal(repo)),
        deleteSavingsGoalProvider.overrideWithValue(DeleteSavingsGoal(repo)),
        setGoalArchivedProvider.overrideWithValue(SetGoalArchived(repo)),
        getSavingsGoalProvider.overrideWithValue(GetSavingsGoal(repo)),
        watchSavingsGoalsProvider.overrideWithValue(WatchSavingsGoals(repo)),
        addGoalContributionProvider.overrideWithValue(
          AddGoalContribution(repo),
        ),
        withdrawFromGoalProvider.overrideWithValue(WithdrawFromGoal(repo)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('GoalFormNotifier', () {
    test('init with null resets to blank form', () {
      final notifier = container.read(goalFormProvider.notifier);
      notifier.init(null);
      final state = container.read(goalFormProvider);

      expect(state.id, isNull);
      expect(state.name, isEmpty);
      expect(state.targetAmountMinor, 0);
      expect(state.currentAmountMinor, 0);
      expect(state.isEditMode, isFalse);
    });

    test('init with existing goal populates all form fields', () {
      final notifier = container.read(goalFormProvider.notifier);
      notifier.init(sampleGoal);
      final state = container.read(goalFormProvider);

      expect(state.id, 'goal-1');
      expect(state.name, 'Vacation to Japan');
      expect(state.targetAmountMinor, 3000000);
      expect(state.currentAmountMinor, 1000000);
      expect(state.targetDate, LocalDate(2026, 12, 1));
      expect(state.iconKey, 'flight');
      expect(state.colorValue, 0xFF1976D2);
      expect(state.notes, 'Winter holiday');
      expect(state.isEditMode, isTrue);
    });

    test(
      'submit rejects empty name and 0 target amount with field errors',
      () async {
        final notifier = container.read(goalFormProvider.notifier);
        notifier.init(null);

        final success = await notifier.submit();
        expect(success, isFalse);

        final state = container.read(goalFormProvider);
        expect(state.fieldErrors.containsKey('name'), isTrue);
        expect(state.fieldErrors.containsKey('targetAmount'), isTrue);
      },
    );

    test('submit succeeds with valid data and saves to repository', () async {
      final notifier = container.read(goalFormProvider.notifier);
      notifier.init(null);
      notifier.setName('New Car');
      notifier.setTargetAmount(15000000);
      notifier.setCurrentAmount(2000000);

      final success = await notifier.submit();
      expect(success, isTrue);

      final goals = await repo.watchGoals().first;
      expect(goals.length, 1);
      expect(goals.first.name, 'New Car');
      expect(goals.first.targetAmount.amountMinor, 15000000);
      expect(goals.first.currentAmount.amountMinor, 2000000);
    });
  });

  group('Goals filtering stream providers', () {
    test(
      'active, completed, and archived providers categorize goals correctly',
      () async {
        // 1. In-progress goal
        await repo.saveGoal(sampleGoal);

        // 2. Completed goal
        final completedGoal = sampleGoal.copyWith(
          id: 'goal-completed',
          name: 'Bought Laptop',
          currentAmount: const Money.minor(3000000, CurrencyCode.mmk),
        );
        await repo.saveGoal(completedGoal);

        // 3. Archived goal
        final archivedGoal = sampleGoal.copyWith(
          id: 'goal-archived',
          name: 'Cancelled Trip',
          isArchived: true,
        );
        await repo.saveGoal(archivedGoal);

        // Listen to stream providers and pump event queue
        final sub1 = container.listen(goalsListStreamProvider, (_, _) {});
        final sub2 = container.listen(allGoalsStreamProvider, (_, _) {});
        await pumpEventQueue();

        // Verify active
        final activeAsync = container.read(activeGoalsProvider);
        expect(activeAsync.value?.length, 1);
        expect(activeAsync.value?.first.id, 'goal-1');

        // Verify completed
        final completedAsync = container.read(completedGoalsProvider);
        expect(completedAsync.value?.length, 1);
        expect(completedAsync.value?.first.id, 'goal-completed');

        // Verify archived
        final archivedAsync = container.read(archivedGoalsProvider);
        expect(archivedAsync.value?.length, 1);
        expect(archivedAsync.value?.first.id, 'goal-archived');

        sub1.close();
        sub2.close();
      },
    );
  });
}
