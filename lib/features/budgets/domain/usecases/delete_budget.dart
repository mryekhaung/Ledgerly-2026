import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';

/// Soft-deletes a budget.
class DeleteBudget implements UseCase<void, String> {
  const DeleteBudget(this._repository);

  final BudgetRepository _repository;

  @override
  Future<Result<void>> call(String id) {
    return _repository.deleteBudget(id);
  }
}
