import 'package:ledgerly/core/database/result_guard.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';

/// Concrete implementation of [BudgetRepository].
class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._dataSource);

  final BudgetLocalDataSource _dataSource;

  @override
  Stream<Result<List<Budget>>> watchBudgets({
    String? periodId,
    bool includeArchived = false,
  }) {
    return guardResultStream(
      _dataSource.watchBudgets(
        periodId: periodId,
        includeArchived: includeArchived,
      ),
    );
  }

  @override
  Future<Result<Budget>> getBudget(String id) {
    return guardResult(
      () async {
        final b = await _dataSource.getBudget(id);
        if (b == null) {
          throw const NotFoundFailure('Budget not found');
        }
        return b;
      },
      onError: (err, st) {
        if (err is Failure) return err;
        return FailureMapper.fromStorage(err, st);
      },
    );
  }

  @override
  Future<Result<Budget>> saveBudget({
    required Budget budget,
    bool isNew = false,
  }) {
    return guardResult(
      () => _dataSource.saveBudget(budget: budget, isNew: isNew),
    );
  }

  @override
  Future<Result<void>> deleteBudget(String id) {
    return guardResult(() => _dataSource.deleteBudget(id));
  }

  @override
  Future<Result<void>> setBudgetArchived(String id, bool isArchived) {
    return guardResult(() => _dataSource.setBudgetArchived(id, isArchived));
  }

  @override
  Future<Result<bool>> hasBudgetForCategory({
    String? categoryId,
    String? periodId,
    String? excludingId,
  }) {
    return guardResult(
      () => _dataSource.hasBudgetForCategory(
        categoryId: categoryId,
        periodId: periodId,
        excludingId: excludingId,
      ),
    );
  }

  @override
  Stream<Result<List<BudgetProgress>>> watchBudgetProgress(
    BudgetPeriod period,
  ) {
    return guardResultStream(_dataSource.watchBudgetProgress(period));
  }

  @override
  Future<Result<List<BudgetProgress>>> getBudgetProgress(BudgetPeriod period) {
    return guardResult(() => _dataSource.getBudgetProgress(period));
  }
}
