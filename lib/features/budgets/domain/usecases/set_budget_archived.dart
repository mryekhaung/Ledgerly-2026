import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';

final class SetBudgetArchivedParams {
  const SetBudgetArchivedParams({required this.id, required this.isArchived});

  final String id;
  final bool isArchived;
}

/// Toggles whether a budget is archived.
class SetBudgetArchived implements UseCase<void, SetBudgetArchivedParams> {
  const SetBudgetArchived(this._repository);

  final BudgetRepository _repository;

  @override
  Future<Result<void>> call(SetBudgetArchivedParams params) {
    return _repository.setBudgetArchived(params.id, params.isArchived);
  }
}
