import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';

/// Contract for budget persistence and progress tracking.
///
/// Pure Dart — no Flutter, no Drift (docs/Agent.md §3.1).
abstract interface class BudgetRepository {
  /// Watches all budgets configured, optionally filtered by [periodId].
  Stream<Result<List<Budget>>> watchBudgets({
    String? periodId,
    bool includeArchived = false,
  });

  /// Retrieves a single budget by its [id].
  Future<Result<Budget>> getBudget(String id);

  /// Saves [budget] (create or update).
  Future<Result<Budget>> saveBudget({
    required Budget budget,
    bool isNew = false,
  });

  /// Soft-deletes a budget by [id].
  Future<Result<void>> deleteBudget(String id);

  /// Sets the archive status of a budget.
  Future<Result<void>> setBudgetArchived(String id, bool isArchived);

  /// Checks if a budget already exists for [categoryId] (null for total budget) in [periodId].
  Future<Result<bool>> hasBudgetForCategory({
    String? categoryId,
    String? periodId,
    String? excludingId,
  });

  /// Streams live progress calculations for all active budgets in [period].
  Stream<Result<List<BudgetProgress>>> watchBudgetProgress(BudgetPeriod period);

  /// Computes a one-shot snapshot of progress for all active budgets in [period].
  Future<Result<List<BudgetProgress>>> getBudgetProgress(BudgetPeriod period);
}
