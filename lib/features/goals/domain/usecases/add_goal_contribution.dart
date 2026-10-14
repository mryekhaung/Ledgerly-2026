import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';
import 'package:ledgerly/features/goals/domain/validators/savings_goal_validators.dart';

final class AddGoalContributionParams {
  const AddGoalContributionParams({
    required this.goalId,
    required this.amountMinor,
    this.fromAccountId,
    this.note,
  });

  final String goalId;
  final int amountMinor;
  final String? fromAccountId;
  final String? note;
}

/// Adds a deposit contribution towards a savings goal.
class AddGoalContribution implements UseCase<void, AddGoalContributionParams> {
  const AddGoalContribution(this._repository);

  final SavingsGoalsRepository _repository;

  @override
  Future<Result<void>> call(AddGoalContributionParams params) async {
    final amountErr = SavingsGoalValidators.validateContributionAmount(
      params.amountMinor,
    );
    if (amountErr != null) {
      return Err<void>(
        ValidationFailure(
          'Contribution amount must be positive',
          fieldErrors: {'amount': amountErr},
        ),
      );
    }

    final notesErr = SavingsGoalValidators.validateNotes(params.note);
    if (notesErr != null) {
      return Err<void>(
        ValidationFailure(
          'Contribution note is too long',
          fieldErrors: {'note': notesErr},
        ),
      );
    }

    return _repository.addContribution(
      goalId: params.goalId,
      amountMinor: params.amountMinor,
      fromAccountId: params.fromAccountId,
      note: params.note,
    );
  }
}
