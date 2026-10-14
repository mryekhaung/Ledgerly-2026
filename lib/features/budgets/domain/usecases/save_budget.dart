import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';
import 'package:ledgerly/features/budgets/domain/validators/budget_validators.dart';

final class SaveBudgetParams {
  const SaveBudgetParams({required this.budget, this.isNew = false});

  final Budget budget;
  final bool isNew;
}

/// Validates and saves a budget limit.
class SaveBudget implements UseCase<Budget, SaveBudgetParams> {
  const SaveBudget(this._repository);

  final BudgetRepository _repository;

  @override
  Future<Result<Budget>> call(SaveBudgetParams params) async {
    final budget = params.budget;

    final amountErr = BudgetValidators.validateAmount(budget.amountMinor);
    if (amountErr != null) {
      return Err<Budget>(
        ValidationFailure(
          'Budget amount must be positive',
          fieldErrors: {'amount': amountErr},
        ),
      );
    }

    final thresholdErr = BudgetValidators.validateThreshold(
      budget.alertThreshold,
    );
    if (thresholdErr != null) {
      return Err<Budget>(
        ValidationFailure(
          'Alert threshold must be between 10% and 100%',
          fieldErrors: {'threshold': thresholdErr},
        ),
      );
    }

    final existsRes = await _repository.hasBudgetForCategory(
      categoryId: budget.categoryId,
      periodId: budget.periodId,
      excludingId: params.isNew ? null : budget.id,
    );

    if (existsRes case Err(:final failure)) return Err<Budget>(failure);
    if (existsRes.valueOrNull ?? false) {
      final errKey = budget.isTotalBudget
          ? BudgetValidators.duplicateTotal
          : BudgetValidators.duplicateCategory;
      return Err<Budget>(
        ValidationFailure(
          budget.isTotalBudget
              ? 'A total budget for this period already exists'
              : 'A budget for this category already exists',
          fieldErrors: {'category': errKey},
        ),
      );
    }

    return _repository.saveBudget(budget: budget, isNew: params.isNew);
  }
}
