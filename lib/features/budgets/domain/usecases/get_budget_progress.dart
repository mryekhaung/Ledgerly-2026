import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';

/// Computes a one-shot snapshot of budget progress for [BudgetPeriod].
class GetBudgetProgress implements UseCase<List<BudgetProgress>, BudgetPeriod> {
  const GetBudgetProgress(this._repository);

  final BudgetRepository _repository;

  @override
  Future<Result<List<BudgetProgress>>> call(BudgetPeriod period) {
    return _repository.getBudgetProgress(period);
  }
}
