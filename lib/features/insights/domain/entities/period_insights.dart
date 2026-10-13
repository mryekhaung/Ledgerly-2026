import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/features/insights/domain/entities/category_breakdown.dart';
import 'package:ledgerly/features/insights/domain/entities/daily_trend_point.dart';
import 'package:ledgerly/features/insights/domain/entities/period_comparison.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';

/// Complete insights and analytics payload for a [BudgetPeriod].
final class PeriodInsights {
  const PeriodInsights({
    required this.period,
    required this.summary,
    required this.comparison,
    required this.categoryBreakdowns,
    required this.trendPoints,
  });

  /// The active budget period.
  final BudgetPeriod period;

  /// Headline figures (income, expense, net).
  final PeriodTotal summary;

  /// Period-over-period comparison with previous period.
  final PeriodComparison comparison;

  /// Expense breakdown per category, ordered by spend descending.
  final List<CategoryBreakdown> categoryBreakdowns;

  /// Daily sequence of income/expense and cumulative cash flow.
  final List<DailyTrendPoint> trendPoints;

  /// True when there is zero activity in the active period.
  bool get isEmpty => summary.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is PeriodInsights &&
      other.period == period &&
      other.summary == summary &&
      other.comparison == comparison &&
      _listEquals(other.categoryBreakdowns, categoryBreakdowns) &&
      _listEquals(other.trendPoints, trendPoints);

  @override
  int get hashCode => Object.hash(
        period,
        summary,
        comparison,
        Object.hashAll(categoryBreakdowns),
        Object.hashAll(trendPoints),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
