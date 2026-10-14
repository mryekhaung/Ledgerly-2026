import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';

final class DeleteSavingsGoalParams {
  const DeleteSavingsGoalParams({required this.id});

  final String id;
}

/// Soft deletes a savings goal.
class DeleteSavingsGoal implements UseCase<void, DeleteSavingsGoalParams> {
  const DeleteSavingsGoal(this._repository);

  final SavingsGoalsRepository _repository;

  @override
  Future<Result<void>> call(DeleteSavingsGoalParams params) {
    return _repository.deleteGoal(params.id);
  }
}
