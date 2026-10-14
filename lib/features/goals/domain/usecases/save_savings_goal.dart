import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';
import 'package:ledgerly/features/goals/domain/validators/savings_goal_validators.dart';

final class SaveSavingsGoalParams {
  const SaveSavingsGoalParams({required this.goal});

  final SavingsGoal goal;
}

/// Validates and saves (creates or updates) a savings goal.
class SaveSavingsGoal implements UseCase<String, SaveSavingsGoalParams> {
  const SaveSavingsGoal(this._repository);

  final SavingsGoalsRepository _repository;

  @override
  Future<Result<String>> call(SaveSavingsGoalParams params) async {
    final goal = params.goal;
    final fieldErrors = <String, String>{};

    final nameErr = SavingsGoalValidators.validateName(goal.name);
    if (nameErr != null) fieldErrors['name'] = nameErr;

    final targetErr = SavingsGoalValidators.validateTargetAmount(
      goal.targetAmount.amountMinor,
    );
    if (targetErr != null) fieldErrors['targetAmount'] = targetErr;

    final currentErr = SavingsGoalValidators.validateCurrentAmount(
      goal.currentAmount.amountMinor,
    );
    if (currentErr != null) fieldErrors['currentAmount'] = currentErr;

    final notesErr = SavingsGoalValidators.validateNotes(goal.notes);
    if (notesErr != null) fieldErrors['notes'] = notesErr;

    if (fieldErrors.isNotEmpty) {
      return Err<String>(
        ValidationFailure(
          'Savings goal validation failed',
          fieldErrors: fieldErrors,
        ),
      );
    }

    return _repository.saveGoal(goal);
  }
}
