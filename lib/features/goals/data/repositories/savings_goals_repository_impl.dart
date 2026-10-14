import 'package:ledgerly/core/database/result_guard.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/goals/data/datasources/savings_goals_local_datasource.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';

/// Concrete implementation of [SavingsGoalsRepository].
class SavingsGoalsRepositoryImpl implements SavingsGoalsRepository {
  const SavingsGoalsRepositoryImpl(this._dataSource);

  final SavingsGoalsLocalDataSource _dataSource;

  @override
  Stream<List<SavingsGoal>> watchGoals({bool includeArchived = false}) {
    return _dataSource.watchAll(includeArchived: includeArchived);
  }

  @override
  Future<Result<SavingsGoal?>> getGoal(String id) {
    return guardResult(() => _dataSource.findById(id));
  }

  @override
  Future<Result<String>> saveGoal(SavingsGoal goal) {
    return guardResult(() => _dataSource.save(goal));
  }

  @override
  Future<Result<void>> addContribution({
    required String goalId,
    required int amountMinor,
    String? fromAccountId,
    String? note,
  }) {
    return guardResult(
      () => _dataSource.addContribution(
        goalId: goalId,
        amountMinor: amountMinor,
        fromAccountId: fromAccountId,
        note: note,
      ),
    );
  }

  @override
  Future<Result<void>> withdraw({
    required String goalId,
    required int amountMinor,
    String? toAccountId,
    String? note,
  }) {
    return guardResult(
      () => _dataSource.withdraw(
        goalId: goalId,
        amountMinor: amountMinor,
        toAccountId: toAccountId,
        note: note,
      ),
    );
  }

  @override
  Future<Result<void>> setArchived({
    required String id,
    required bool archived,
  }) {
    return guardResult(
      () => _dataSource.setArchived(id: id, isArchived: archived),
    );
  }

  @override
  Future<Result<void>> deleteGoal(String id) {
    return guardResult(() => _dataSource.delete(id));
  }
}
