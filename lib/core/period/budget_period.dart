/// A closed-inclusive date range that the app treats as one "month".
///
/// The user may start their month on any day 1–28 (their pay day), so a period
/// can span two calendar months — Oct 10 → Nov 9, not Oct 1 → Oct 31. Every
/// month-shaped concern in the app (calendar grid, summaries, budgets, insights,
/// export ranges, "this/last period") keys on this type instead of on a calendar
/// month, so changing `monthStartDay` changes nothing in the data, only how the
/// ranges are computed (docs/DataModel.md §8, docs/Agent.md §3.15).
///
/// Pure Dart — no Flutter, no `dart:io` (docs/Agent.md §3.1). `core/period` is
/// the single source of month-shape logic.
library;

import 'package:ledgerly/core/utils/local_date.dart';

/// A single budget period: `[start, end]`, both ends inclusive.
///
/// Two periods never share a day — [end] is exactly the day before the next
/// period's [start], so a transaction dated on a boundary lands in exactly one
/// period.
final class BudgetPeriod {
  /// Creates a period; [end] must not precede [start].
  BudgetPeriod({required this.start, required this.end})
    : assert(
        !end.isBefore(start),
        'A BudgetPeriod must end on or after its start.',
      );

  /// First day of the period (inclusive).
  final LocalDate start;

  /// Last day of the period (inclusive).
  final LocalDate end;

  /// Stable identifier: `yyyy-MM` of the *start* date.
  ///
  /// Oct 10 – Nov 9 → `2026-10`. Budgets (v0.3), goals' monthly targets,
  /// insights and "previous period" comparisons all key on this string
  /// (docs/DataModel.md §8), so it must stay stable for a given start.
  String get id {
    final year = start.year.toString();
    final month = start.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  /// Number of days in the period, inclusive (always ≥ 28 for a valid period).
  int get length => end.daysSince(start) + 1;

  /// True when [date] falls within `[start, end]` inclusive.
  bool contains(LocalDate date) => !date.isBefore(start) && !date.isAfter(end);

  @override
  bool operator ==(Object other) =>
      other is BudgetPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start – $end';
}
