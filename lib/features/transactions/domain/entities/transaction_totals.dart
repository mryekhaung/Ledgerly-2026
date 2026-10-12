import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

/// A per-day net total, produced by a SQL `GROUP BY`
/// (`docs/Architecture.md` §7 — aggregation happens in SQL, never a Dart loop).
///
/// Deliberately a distinct type from [Transaction]: it has no id, no category
/// and no note, and conflating the two would make it possible to pass a summary
/// where a row is expected.
final class DailyTotal {
  /// Creates a day's total.
  const DailyTotal({
    required this.date,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.currency,
  });

  /// The day this total covers.
  final LocalDate date;

  /// Money in that day, as a positive magnitude.
  final int incomeMinor;

  /// Money out that day, as a positive magnitude.
  ///
  /// Kept positive and separate from [incomeMinor] so the UI can render the two
  /// sides independently — a day with 100 in and 100 out is not "zero activity"
  /// to a user looking at the calendar.
  final int expenseMinor;

  /// The currency both totals are denominated in.
  final CurrencyCode currency;

  /// Income minus expense for the day. Signed — negative means net spending.
  ///
  /// Computed here rather than stored, so there is exactly one definition
  /// (`docs/DataModel.md` §3: totals are never persisted).
  int get netMinor => incomeMinor - expenseMinor;

  /// True when the day had any activity at all.
  bool get hasActivity => incomeMinor != 0 || expenseMinor != 0;

  /// A zeroed total for [date] in [currency].
  ///
  /// The day-list summary card needs a renderable "nothing happened" value the
  /// moment the user taps an empty day, so a caller never has to unwrap a null
  /// just to draw a zero. Mirrors [MonthTotal.empty].
  factory DailyTotal.empty(LocalDate date, CurrencyCode currency) => DailyTotal(
    date: date,
    incomeMinor: 0,
    expenseMinor: 0,
    currency: currency,
  );

  /// The dominant direction for capsule intensity: which way the day leans.
  ///
  /// Returns null for a day with no activity, so a caller must handle that case
  /// rather than render a misleading neutral colour.
  TransactionDirection? get dominantDirection {
    if (!hasActivity) return null;
    return netMinor >= 0
        ? TransactionDirection.income
        : TransactionDirection.expense;
  }

  @override
  bool operator ==(Object other) =>
      other is DailyTotal &&
      other.date == date &&
      other.incomeMinor == incomeMinor &&
      other.expenseMinor == expenseMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(date, incomeMinor, expenseMinor, currency);

  @override
  String toString() =>
      'DailyTotal($date, +$incomeMinor, -$expenseMinor, net $netMinor)';
}

/// A per-category total over a period — the donut chart's datum.
final class CategoryTotal {
  /// Creates a category total.
  const CategoryTotal({
    required this.categoryId,
    required this.direction,
    required this.amountMinor,
    required this.currency,
  });

  /// The category this total belongs to.
  final String categoryId;

  /// Which direction the total aggregates.
  final TransactionDirection direction;

  /// The total, as a positive magnitude.
  final int amountMinor;

  /// The currency the total is denominated in.
  final CurrencyCode currency;

  @override
  bool operator ==(Object other) =>
      other is CategoryTotal &&
      other.categoryId == categoryId &&
      other.direction == direction &&
      other.amountMinor == amountMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(categoryId, direction, amountMinor, currency);

  @override
  String toString() =>
      'CategoryTotal($categoryId, ${direction.name}, $amountMinor)';
}

/// A month's headline figures — the summary card
/// (`docs/Design.md` §6.3).
final class MonthTotal {
  /// Creates a month summary.
  const MonthTotal({
    required this.month,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.currency,
  });

  /// A zeroed summary for [month] in [currency].
  ///
  /// Exists so a screen has an honest empty state instead of a nullable it must
  /// unwrap — "no transactions this month" is a real, renderable fact, not a
  /// missing value.
  factory MonthTotal.empty(LocalDate month, CurrencyCode currency) =>
      MonthTotal(
        month: month.firstDayOfMonth,
        incomeMinor: 0,
        expenseMinor: 0,
        currency: currency,
      );

  /// The month this summary covers, normalised to its first day.
  final LocalDate month;

  /// Money in for the month, as a positive magnitude.
  final int incomeMinor;

  /// Money out for the month, as a positive magnitude.
  final int expenseMinor;

  /// The currency both totals are denominated in.
  final CurrencyCode currency;

  /// Income minus expense. Signed.
  int get netMinor => incomeMinor - expenseMinor;

  /// True when the month has no activity.
  bool get isEmpty => incomeMinor == 0 && expenseMinor == 0;

  @override
  bool operator ==(Object other) =>
      other is MonthTotal &&
      other.month == month &&
      other.incomeMinor == incomeMinor &&
      other.expenseMinor == expenseMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(month, incomeMinor, expenseMinor, currency);

  @override
  String toString() =>
      'MonthTotal($month, +$incomeMinor, -$expenseMinor, net $netMinor)';
}
