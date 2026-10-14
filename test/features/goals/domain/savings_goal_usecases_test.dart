import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';
import 'package:ledgerly/features/goals/domain/usecases/add_goal_contribution.dart';
import 'package:ledgerly/features/goals/domain/usecases/delete_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/get_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/save_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/set_goal_archived.dart';
import 'package:ledgerly/features/goals/domain/usecases/watch_savings_goals.dart';
import 'package:ledgerly/features/goals/domain/usecases/withdraw_from_goal.dart';

class FakeSavingsGoalsRepository implements SavingsGoalsRepository {
  final Map<String, SavingsGoal> _goals = {};

  @override
  Stream<List<SavingsGoal>> watchGoals({bool includeArchived = false}) {
    final list = _goals.values
        .where((g) => includeArchived || !g.isArchived)
        .toList();
    return Stream.value(list);
  }

  @override
  Future<Result<SavingsGoal?>> getGoal(String id) async {
    return Success(_goals[id]);
  }

  @override
  Future<Result<String>> saveGoal(SavingsGoal goal) async {
    _goals[goal.id] = goal;
    return Success(goal.id);
  }

  @override
  Future<Result<void>> addContribution({
    required String goalId,
    required int amountMinor,
    String? fromAccountId,
    String? note,
  }) async {
    final goal = _goals[goalId];
    if (goal == null) return const Err(NotFoundFailure('Goal not found'));
    final updated = goal.copyWith(
      currentAmount: Money.minor(
        goal.currentAmount.amountMinor + amountMinor,
        goal.currentAmount.currency,
      ),
    );
    _goals[goalId] = updated;
    return const Success(null);
  }

  @override
  Future<Result<void>> withdraw({
    required String goalId,
    required int amountMinor,
    String? toAccountId,
    String? note,
  }) async {
    final goal = _goals[goalId];
    if (goal == null) return const Err(NotFoundFailure('Goal not found'));
    final updated = goal.copyWith(
      currentAmount: Money.minor(
        goal.currentAmount.amountMinor - amountMinor,
        goal.currentAmount.currency,
      ),
    );
    _goals[goalId] = updated;
    return const Success(null);
  }

  @override
  Future<Result<void>> setArchived({
    required String id,
    required bool archived,
  }) async {
    final goal = _goals[id];
    if (goal == null) return const Err(NotFoundFailure('Goal not found'));
    _goals[id] = goal.copyWith(isArchived: archived);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteGoal(String id) async {
    _goals.remove(id);
    return const Success(null);
  }
}

void main() {
  late FakeSavingsGoalsRepository repo;
  late WatchSavingsGoals watchSavingsGoals;
  late GetSavingsGoal getSavingsGoal;
  late SaveSavingsGoal saveSavingsGoal;
  late AddGoalContribution addGoalContribution;
  late WithdrawFromGoal withdrawFromGoal;
  late SetGoalArchived setGoalArchived;
  late DeleteSavingsGoal deleteSavingsGoal;

  final testGoal = SavingsGoal(
    id: 'goal-1',
    name: 'Emergency Fund',
    targetAmount: const Money.minor(1000000, CurrencyCode.mmk),
    currentAmount: const Money.minor(200000, CurrencyCode.mmk),
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  setUp(() {
    repo = FakeSavingsGoalsRepository();
    watchSavingsGoals = WatchSavingsGoals(repo);
    getSavingsGoal = GetSavingsGoal(repo);
    saveSavingsGoal = SaveSavingsGoal(repo);
    addGoalContribution = AddGoalContribution(repo);
    withdrawFromGoal = WithdrawFromGoal(repo);
    setGoalArchived = SetGoalArchived(repo);
    deleteSavingsGoal = DeleteSavingsGoal(repo);
  });

  group('Savings Goals Usecases', () {
    test('saveSavingsGoal successfully validates and saves', () async {
      final res = await saveSavingsGoal(SaveSavingsGoalParams(goal: testGoal));
      expect(res.isSuccess, isTrue);

      final readRes = await getSavingsGoal(
        const GetSavingsGoalParams(id: 'goal-1'),
      );
      expect(readRes.isSuccess, isTrue);
      expect(readRes.valueOrNull?.name, 'Emergency Fund');
    });

    test(
      'saveSavingsGoal rejects invalid goal name or target amount',
      () async {
        final invalid = testGoal.copyWith(name: '');
        final res = await saveSavingsGoal(SaveSavingsGoalParams(goal: invalid));
        expect(res.isErr, isTrue);
        expect(res.failureOrNull, isA<ValidationFailure>());
      },
    );

    test('watchSavingsGoals emits saved goals', () async {
      await saveSavingsGoal(SaveSavingsGoalParams(goal: testGoal));
      final list = await watchSavingsGoals().first;
      expect(list.length, 1);
      expect(list.first.id, 'goal-1');
    });

    test('addGoalContribution updates goal currentAmount', () async {
      await saveSavingsGoal(SaveSavingsGoalParams(goal: testGoal));
      final res = await addGoalContribution(
        const AddGoalContributionParams(goalId: 'goal-1', amountMinor: 50000),
      );
      expect(res.isSuccess, isTrue);

      final updated = (await getSavingsGoal(
        const GetSavingsGoalParams(id: 'goal-1'),
      )).valueOrNull!;
      expect(updated.currentAmount.amountMinor, 250000);
    });

    test('withdrawFromGoal reduces currentAmount', () async {
      await saveSavingsGoal(SaveSavingsGoalParams(goal: testGoal));
      final res = await withdrawFromGoal(
        const WithdrawFromGoalParams(
          goalId: 'goal-1',
          amountMinor: 50000,
          currentAmountMinor: 200000,
        ),
      );
      expect(res.isSuccess, isTrue);

      final updated = (await getSavingsGoal(
        const GetSavingsGoalParams(id: 'goal-1'),
      )).valueOrNull!;
      expect(updated.currentAmount.amountMinor, 150000);
    });

    test('setGoalArchived toggles archived flag', () async {
      await saveSavingsGoal(SaveSavingsGoalParams(goal: testGoal));
      final res = await setGoalArchived(
        const SetGoalArchivedParams(id: 'goal-1', archived: true),
      );
      expect(res.isSuccess, isTrue);

      final updated = (await getSavingsGoal(
        const GetSavingsGoalParams(id: 'goal-1'),
      )).valueOrNull!;
      expect(updated.isArchived, isTrue);
    });

    test('deleteSavingsGoal removes goal', () async {
      await saveSavingsGoal(SaveSavingsGoalParams(goal: testGoal));
      final res = await deleteSavingsGoal(
        const DeleteSavingsGoalParams(id: 'goal-1'),
      );
      expect(res.isSuccess, isTrue);

      final readRes = await getSavingsGoal(
        const GetSavingsGoalParams(id: 'goal-1'),
      );
      expect(readRes.valueOrNull, isNull);
    });
  });
}
