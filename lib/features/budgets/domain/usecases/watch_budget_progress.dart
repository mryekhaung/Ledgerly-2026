import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';

/// Streams computed progress for all active budgets in [BudgetPeriod].
class WatchBudgetProgress
    implements StreamUseCase<List<BudgetProgress>, BudgetPeriod> {
  const WatchBudgetProgress(this._repository);

  final BudgetRepository _repository;

  @override
  Stream<Result<List<BudgetProgress>>> call(BudgetPeriod period) {
    return _repository.watchBudgetProgress(period);
  }
}
