import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_status.dart';

/// Computed progress and live analytics for a budget in a given [period].
///
/// Pure Dart — no Flutter, no Drift (docs/Agent.md §3.1).
final class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spentMinor,
    required this.period,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  /// The underlying budget configuration.
  final Budget budget;

  /// Total money spent in minor units within [period].
  final int spentMinor;

  /// The budget period this progress applies to.
  final BudgetPeriod period;

  /// Resolved display name of the category, or null if total period budget.
  final String? categoryName;

  /// Resolved icon key of the category, or null if total period budget.
  final String? categoryIcon;

  /// Resolved ARGB color of the category, or null if total period budget.
  final int? categoryColor;

  /// Money remaining before the budget cap is breached (signed: negative if over budget).
  int get remainingMinor => budget.amountMinor - spentMinor;

  /// Fraction of the budget spent (e.g. 0.75 for 75%).
  double get spentRatio {
    if (budget.amountMinor <= 0) return 0.0;
    return spentMinor / budget.amountMinor;
  }

  /// Percentage of the budget spent (0.0 to 100.0+).
  double get spentPercentage => ((spentRatio * 10000).round()) / 100.0;

  /// Progress bar fraction clamped between 0.0 and 1.0.
  double get progressFraction => spentRatio.clamp(0.0, 1.0);

  /// Whether the user has exceeded the allocated limit.
  bool get isOverBudget => spentMinor > budget.amountMinor;

  /// Whether this progress corresponds to an overall total budget.
  bool get isTotalBudget => budget.isTotalBudget;

  /// Whether this progress corresponds to a category-specific budget.
  bool get isCategoryBudget => budget.isCategoryBudget;

  /// Whether the user has reached or exceeded the alert threshold (e.g. >= 80%) without breaching.
  bool get isNearLimit => spentRatio >= budget.alertThreshold && !isOverBudget;

  /// Visual status pill classification.
  BudgetStatus get status {
    if (isOverBudget) return BudgetStatus.exceeded;
    if (isNearLimit) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }

  /// Calculates safe daily spending budget based on remaining days in the period.
  int dailyRemainingMinor(int daysRemaining) {
    if (daysRemaining <= 0 || remainingMinor <= 0) return 0;
    return (remainingMinor / daysRemaining).round();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetProgress &&
        other.budget == budget &&
        other.spentMinor == spentMinor &&
        other.period == period &&
        other.categoryName == categoryName &&
        other.categoryIcon == categoryIcon &&
        other.categoryColor == categoryColor;
  }

  @override
  int get hashCode => Object.hash(
    budget,
    spentMinor,
    period,
    categoryName,
    categoryIcon,
    categoryColor,
  );

  @override
  String toString() =>
      'BudgetProgress(budget: ${budget.id}, spent: $spentMinor/${budget.amountMinor}, status: ${status.name})';
}
