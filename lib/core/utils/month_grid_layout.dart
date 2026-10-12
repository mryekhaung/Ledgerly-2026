import 'package:ledgerly/core/utils/local_date.dart';

/// Which day the calendar grid starts its week on.
///
/// A pure-Dart mirror of the settings enum: `core/` sits below `features/`, so
/// it cannot import `features/settings/domain/entities/app_settings.dart`
/// without inverting the dependency (`docs/Architecture.md` §2). The settings
/// layer converts one to the other where they meet.
enum GridWeekStart {
  monday,
  sunday;

  /// The `DateTime` weekday of the first column (1 = Monday, 7 = Sunday).
  int get isoWeekday => this == GridWeekStart.monday ? 1 : 7;
}

/// The cell layout of a month grid, as pure data.
///
/// Extracted from the widget so the one part of the calendar that is easy to get
/// subtly wrong — how many blank cells precede the 1st, and how many trailing
/// cells the last week needs — is unit-testable without a widget tree
/// (`docs/Agent.md` §6).
///
/// Weeks are **Monday-first by default**, matching the ISO weekday numbering
/// [LocalDate] exposes. [GridWeekStart.sunday] is supported because the Settings
/// page offers it; every method takes the start as a parameter rather than
/// storing it, so the layout stays a pure function of its inputs and two
/// calendars with different settings cannot share mutable state.
abstract final class MonthGridLayout {
  const MonthGridLayout._();

  /// Days in a week. Named rather than using `DateTime.daysPerWeek` so this
  /// stays pure Dart and does not depend on `dart:core`'s date constants.
  static const int daysPerWeek = 7;

  /// How many blank cells precede day 1.
  ///
  /// A month beginning on the start day needs none; on the day before it needs
  /// six. Derived from [LocalDate.isoWeekday], where Monday is 1.
  ///
  /// For a Sunday-first grid the whole week is rotated one day, so the offset is
  /// the ISO weekday taken modulo 7 — Sunday (7) becomes 0 and Monday (1)
  /// becomes 1.
  static int leadingBlanks(
    LocalDate month, {
    GridWeekStart weekStart = GridWeekStart.monday,
  }) => switch (weekStart) {
    GridWeekStart.monday => month.isoWeekday - 1,
    GridWeekStart.sunday => month.isoWeekday % daysPerWeek,
  };

  /// Total cells including the leading and trailing blanks, always a multiple
  /// of [daysPerWeek].
  static int cellCount(
    LocalDate month, {
    GridWeekStart weekStart = GridWeekStart.monday,
  }) {
    final used =
        leadingBlanks(month, weekStart: weekStart) +
        LocalDate.daysInMonth(month.year, month.month);
    // Integer ceiling division — avoids a `double` that could round the wrong
    // way on a 31-day month starting on a Sunday (37 cells → 6 rows).
    return ((used + daysPerWeek - 1) ~/ daysPerWeek) * daysPerWeek;
  }

  /// The day occupying [cellIndex], or null for a blank.
  ///
  /// A blank cell after the last day is `null` just like one before the 1st, so
  /// the caller renders both the same way and the grid never gains a row of
  /// phantom dates.
  static LocalDate? dayAt(
    LocalDate month,
    int cellIndex, {
    GridWeekStart weekStart = GridWeekStart.monday,
  }) {
    final day = cellIndex - leadingBlanks(month, weekStart: weekStart) + 1;
    if (day < 1 || day > LocalDate.daysInMonth(month.year, month.month)) {
      return null;
    }
    return LocalDate(month.year, month.month, day);
  }

  /// The cells of [month], row-major, with nulls for the blanks.
  static List<LocalDate?> cells(
    LocalDate month, {
    GridWeekStart weekStart = GridWeekStart.monday,
  }) => <LocalDate?>[
    for (var index = 0; index < cellCount(month, weekStart: weekStart); index++)
      dayAt(month, index, weekStart: weekStart),
  ];
}
