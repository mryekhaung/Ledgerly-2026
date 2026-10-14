import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';

/// Parameters for watching goals.
final class WatchSavingsGoalsParams {
  const WatchSavingsGoalsParams({this.includeArchived = false});

  final bool includeArchived;
}

/// Watches the live stream of savings goals.
class WatchSavingsGoals {
  const WatchSavingsGoals(this._repository);

  final SavingsGoalsRepository _repository;

  Stream<List<SavingsGoal>> call([
    WatchSavingsGoalsParams params = const WatchSavingsGoalsParams(),
  ]) {
    return _repository.watchGoals(includeArchived: params.includeArchived);
  }
}
