import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';

/// Retrieves a single budget by its id.
class GetBudget implements UseCase<Budget, String> {
  const GetBudget(this._repository);

  final BudgetRepository _repository;

  @override
  Future<Result<Budget>> call(String id) {
    return _repository.getBudget(id);
  }
}
