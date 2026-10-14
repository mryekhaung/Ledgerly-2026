import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/utils/local_date.dart';

/// A single day's cumulative cash flow and income/expense totals.
/// Backs the cash flow trend line chart and income vs expense bar chart.
final class DailyTrendPoint {
  const DailyTrendPoint({
    required this.date,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.cumulativeNetMinor,
    required this.currency,
  });

  /// The day covered.
  final LocalDate date;

  /// Income on this day in minor units.
  final int incomeMinor;

  /// Expense on this day in minor units.
  final int expenseMinor;

  /// Running total of net balance (income - expense) from period start up to this date.
  final int cumulativeNetMinor;

  /// Currency for this data point.
  final CurrencyCode currency;

  /// Net balance on this single day.
  int get netMinor => incomeMinor - expenseMinor;

  @override
  bool operator ==(Object other) =>
      other is DailyTrendPoint &&
      other.date == date &&
      other.incomeMinor == incomeMinor &&
      other.expenseMinor == expenseMinor &&
      other.cumulativeNetMinor == cumulativeNetMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(
    date,
    incomeMinor,
    expenseMinor,
    cumulativeNetMinor,
    currency,
  );

  @override
  String toString() =>
      'DailyTrendPoint($date, +$incomeMinor, -$expenseMinor, cumNet: $cumulativeNetMinor)';
}
