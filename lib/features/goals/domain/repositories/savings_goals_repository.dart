import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';

/// Contract for savings goal persistence and transactions.
///
/// Follows Clean Architecture domain boundary rules: pure Dart.
abstract class SavingsGoalsRepository {
  /// Watches all savings goals, ordered by sort order / created date.
  Stream<List<SavingsGoal>> watchGoals({bool includeArchived = false});

  /// Reads a single goal by its [id].
  Future<Result<SavingsGoal?>> getGoal(String id);

  /// Saves (creates or updates) a goal.
  Future<Result<String>> saveGoal(SavingsGoal goal);

  /// Adds a contribution deposit towards a savings goal.
  ///
  /// Optionally records a transaction on [fromAccountId] if provided.
  Future<Result<void>> addContribution({
    required String goalId,
    required int amountMinor,
    String? fromAccountId,
    String? note,
  });

  /// Withdraws funds from a savings goal.
  ///
  /// Optionally records a transaction on [toAccountId] if provided.
  Future<Result<void>> withdraw({
    required String goalId,
    required int amountMinor,
    String? toAccountId,
    String? note,
  });

  /// Sets the archived state of a goal.
  Future<Result<void>> setArchived({
    required String id,
    required bool archived,
  });

  /// Soft deletes a savings goal.
  Future<Result<void>> deleteGoal(String id);
}
