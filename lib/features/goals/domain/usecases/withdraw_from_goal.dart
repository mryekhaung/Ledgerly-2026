import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';
import 'package:ledgerly/features/goals/domain/validators/savings_goal_validators.dart';

final class WithdrawFromGoalParams {
  const WithdrawFromGoalParams({
    required this.goalId,
    required this.amountMinor,
    required this.currentAmountMinor,
    this.toAccountId,
    this.note,
  });

  final String goalId;
  final int amountMinor;
  final int currentAmountMinor;
  final String? toAccountId;
  final String? note;
}

/// Withdraws funds from a savings goal.
class WithdrawFromGoal implements UseCase<void, WithdrawFromGoalParams> {
  const WithdrawFromGoal(this._repository);

  final SavingsGoalsRepository _repository;

  @override
  Future<Result<void>> call(WithdrawFromGoalParams params) async {
    final amountErr = SavingsGoalValidators.validateWithdrawalAmount(
      amountMinor: params.amountMinor,
      currentAmountMinor: params.currentAmountMinor,
    );
    if (amountErr != null) {
      return Err<void>(
        ValidationFailure(
          'Withdrawal amount invalid',
          fieldErrors: {'amount': amountErr},
        ),
      );
    }

    final notesErr = SavingsGoalValidators.validateNotes(params.note);
    if (notesErr != null) {
      return Err<void>(
        ValidationFailure(
          'Withdrawal note is too long',
          fieldErrors: {'note': notesErr},
        ),
      );
    }

    return _repository.withdraw(
      goalId: params.goalId,
      amountMinor: params.amountMinor,
      toAccountId: params.toAccountId,
      note: params.note,
    );
  }
}
