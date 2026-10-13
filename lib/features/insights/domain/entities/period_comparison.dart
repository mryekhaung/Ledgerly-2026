import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';

/// Comparative analytics comparing the current budget period with the previous one.
final class PeriodComparison {
  const PeriodComparison({
    required this.current,
    required this.previous,
  });

  /// The headline figures for the active budget period.
  final PeriodTotal current;

  /// The headline figures for the previous budget period.
  final PeriodTotal previous;

  /// Difference in expense: positive means more spent, negative means saved.
  int get expenseDeltaMinor => current.expenseMinor - previous.expenseMinor;

  /// Difference in income: positive means higher income.
  int get incomeDeltaMinor => current.incomeMinor - previous.incomeMinor;

  /// Difference in net balance.
  int get netDeltaMinor => current.netMinor - previous.netMinor;

  /// Expense percentage difference relative to previous period.
  /// Returns null if previous period had 0 expense.
  double? get expenseDeltaPercentage {
    if (previous.expenseMinor == 0) return null;
    return ((current.expenseMinor - previous.expenseMinor) /
            previous.expenseMinor) *
        100.0;
  }

  /// Income percentage difference relative to previous period.
  /// Returns null if previous period had 0 income.
  double? get incomeDeltaPercentage {
    if (previous.incomeMinor == 0) return null;
    return ((current.incomeMinor - previous.incomeMinor) /
            previous.incomeMinor) *
        100.0;
  }

  @override
  bool operator ==(Object other) =>
      other is PeriodComparison &&
      other.current == current &&
      other.previous == previous;

  @override
  int get hashCode => Object.hash(current, previous);

  @override
  String toString() =>
      'PeriodComparison(current: $current, previous: $previous, expenseDelta: $expenseDeltaMinor)';
}
