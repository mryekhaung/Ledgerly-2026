/// Computes [BudgetPeriod]s for a given month-start day.
///
/// This is the one place month-shape logic lives. Screens and queries take a
/// [BudgetPeriod] and never assume a calendar month, so the `monthStartDay`
/// setting is a pure view change (docs/DataModel.md §8, docs/Agent.md §3.15).
///
/// Pure Dart — no Flutter, no `dart:io` (docs/Agent.md §3.1).
library;

import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';

/// Derives budget periods from a fixed [startDay].
///
/// [startDay] is the day of the month (1–28) on which each period begins. `1`
/// means an ordinary calendar month. The cap at 28 exists because every month
/// has days 1–28, so a period never needs "start on the 31st" clamping and
/// February is unambiguous (docs/DataModel.md §8).
final class PeriodCalculator {
  /// Creates a calculator; asserts [startDay] is within 1–28.
  PeriodCalculator(this.startDay)
    : assert(
        startDay >= 1 && startDay <= 28,
        'monthStartDay must be 1..28 (docs/DataModel.md §8).',
      );

  /// Day of the month (1–28) on which each period begins.
  final int startDay;

  /// The period that contains [date].
  ///
  /// If `date.day` >= [startDay] the period starts on [startDay] of [date]'s
  /// own month; otherwise it began in the previous calendar month. The end is
  /// the day before the next period's start (docs/DataModel.md §8).
  BudgetPeriod containing(LocalDate date) {
    final LocalDate periodStart;
    if (date.day >= startDay) {
      periodStart = LocalDate(date.year, date.month, startDay);
    } else {
      final firstOfMonth = LocalDate(date.year, date.month, 1);
      final previousMonth = firstOfMonth.addMonths(-1)!;
      periodStart = LocalDate(
        previousMonth.year,
        previousMonth.month,
        startDay,
      );
    }
    return BudgetPeriod(start: periodStart, end: _endAfter(periodStart));
  }

  /// The period immediately after [period].
  BudgetPeriod next(BudgetPeriod period) => containing(period.end.addDays(1)!);

  /// The period immediately before [period].
  BudgetPeriod previous(BudgetPeriod period) =>
      containing(period.start.addDays(-1)!);

  /// Last day of the period that begins on [periodStart].
  ///
  /// `periodStart.day` equals [startDay] by construction, and [startDay] ≤ 28,
  /// so `addMonths(1)` always lands on the same day number in the following
  /// calendar month (every month has ≥ 28 days — no clamping). The end is one
  /// day before that next start.
  LocalDate _endAfter(LocalDate periodStart) {
    final nextStart = periodStart.addMonths(1)!;
    return nextStart.addDays(-1)!;
  }
}
