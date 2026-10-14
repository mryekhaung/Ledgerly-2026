import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';

final class SetGoalArchivedParams {
  const SetGoalArchivedParams({required this.id, required this.archived});

  final String id;
  final bool archived;
}

/// Toggles a goal's archived status.
class SetGoalArchived implements UseCase<void, SetGoalArchivedParams> {
  const SetGoalArchived(this._repository);

  final SavingsGoalsRepository _repository;

  @override
  Future<Result<void>> call(SetGoalArchivedParams params) {
    return _repository.setArchived(id: params.id, archived: params.archived);
  }
}
