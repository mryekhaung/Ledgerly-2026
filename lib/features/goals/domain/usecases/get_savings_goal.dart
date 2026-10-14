import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';

final class GetSavingsGoalParams {
  const GetSavingsGoalParams({required this.id});

  final String id;
}

/// Retrieves a single savings goal by id.
class GetSavingsGoal implements UseCase<SavingsGoal?, GetSavingsGoalParams> {
  const GetSavingsGoal(this._repository);

  final SavingsGoalsRepository _repository;

  @override
  Future<Result<SavingsGoal?>> call(GetSavingsGoalParams params) {
    return _repository.getGoal(params.id);
  }
}
