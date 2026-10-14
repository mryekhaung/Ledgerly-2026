import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';

final class WatchBudgetsParams {
  const WatchBudgetsParams({this.periodId, this.includeArchived = false});

  final String? periodId;
  final bool includeArchived;
}

/// Watches the list of budgets, optionally filtered by period.
class WatchBudgets implements StreamUseCase<List<Budget>, WatchBudgetsParams> {
  const WatchBudgets(this._repository);

  final BudgetRepository _repository;

  @override
  Stream<Result<List<Budget>>> call(WatchBudgetsParams params) {
    return _repository.watchBudgets(
      periodId: params.periodId,
      includeArchived: params.includeArchived,
    );
  }
}
