/// A calendar date with no time component and no time zone.
///
/// Transaction dates are calendar days, not instants: a purchase made at 23:00
/// on the 3rd belongs to the 3rd, regardless of the device's zone or DST. Using
/// `DateTime` for this invites off-by-one bugs the moment the device travels,
/// so the domain stores a **packed `yyyyMMdd` integer** instead and converts to
/// `DateTime` only at the storage/formatting boundary.
///
/// Packed form sorts lexicographically in the same order as chronologically,
/// which makes it a valid Drift/SQLite column type and index key.
///
/// Pure Dart — no Flutter, no `dart:io` (docs/Agent.md §3.1).
library;

/// A date-only value in the proleptic Gregorian calendar.
///
/// Invariants, enforced by every constructor:
/// - `year` is in `[1, 9999]` — the range a packed `yyyyMMdd` can represent.
/// - `month` is in `[1, 12]`.
/// - `day` is valid for that month/year (leap years respected).
final class LocalDate implements Comparable<LocalDate> {
  /// Creates a date from its components.
  ///
  /// Throws [InvalidDateError] when the combination is not a real calendar date
  /// (e.g. `2/30`, month `13`, year `0`). Prefer [tryCreate] when the input
  /// comes from a user or a file.
  factory LocalDate(int year, int month, int day) {
    final result = tryCreate(year, month, day);
    if (result == null) {
      throw InvalidDateError(year, month, day);
    }
    return result;
  }

  /// Creates a date from its components, or returns null when invalid.
  ///
  /// The null-returning form used at trust boundaries (CSV import, text fields)
  /// so callers can map the failure to a `ValidationFailure` rather than
  /// catching an exception (docs/Architecture.md §8).
  static LocalDate? tryCreate(int year, int month, int day) {
    if (year < 1 || year > 9999) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > _daysInMonth(year, month)) return null;
    return LocalDate._packed(year * 10000 + month * 100 + day);
  }

  /// Wraps an already-validated packed `yyyyMMdd` integer.
  const LocalDate._packed(this.value);

  /// Creates a [LocalDate] from a packed `yyyyMMdd` integer.
  ///
  /// Returns null when [value] is not a real date — `20260230` is rejected, not
  /// silently rolled forward.
  static LocalDate? fromPacked(int value) {
    // The packed range matches the `year` invariant (`[1, 9999]`): the smallest
    // representable date is 1-01-01 → 10101, the largest is 9999-12-31.
    // `tryCreate` re-validates the month/day, so a well-formed but impossible
    // date (`20260230`) is still rejected rather than rolled forward.
    if (value < 10101 || value > 99991231) return null;
    final year = value ~/ 10000;
    final month = (value ~/ 100) % 100;
    final day = value % 100;
    return tryCreate(year, month, day);
  }

  /// Creates a [LocalDate] from a [DateTime], discarding its time and zone.
  ///
  /// Uses the **local** calendar fields (`year`/`month`/`day`), which is what a
  /// user means by "today". Use `fromUtc` to read a UTC instant's calendar day.
  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate(dateTime.year, dateTime.month, dateTime.day);

  /// Creates a [LocalDate] from a [DateTime]'s **UTC** calendar fields.
  ///
  /// For interpreting a stored instant (e.g. a sync timestamp) as a day.
  factory LocalDate.fromUtc(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return LocalDate(utc.year, utc.month, utc.day);
  }

  /// The date as a packed `yyyyMMdd` integer, e.g. `2026-10-10` → `20261010`.
  ///
  /// This is the canonical stored/serialised form.
  final int value;

  /// The four-digit year.
  int get year => value ~/ 10000;

  /// The month, 1-12.
  int get month => (value ~/ 100) % 100;

  /// The day of the month, 1-31.
  int get day => value % 100;

  /// Converts to a local [DateTime] at midnight.
  ///
  /// For display formatting and interop only — never use the result for date
  /// arithmetic, which is the bug this type exists to prevent.
  DateTime toDateTime() => DateTime(year, month, day);

  /// The packed value as a `DateTime` in UTC at midnight.
  ///
  /// Deterministic across zones — the right form for serialising to a remote or
  /// comparing against UTC-based timestamps.
  DateTime toUtcDateTime() => DateTime.utc(year, month, day);

  /// The number of days in [month] of [year], respecting leap years.
  ///
  /// Exposed so callers (e.g. a calendar grid) can size a month without
  /// constructing a date first.
  static int daysInMonth(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be 1..12');
    }
    return _daysInMonth(year, month);
  }

  /// True when [year] is a leap year in the proleptic Gregorian calendar.
  ///
  /// Divisible by 4, except centuries, unless divisible by 400 — so 2000 is a
  /// leap year but 1900 is not.
  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// Adds [days] calendar days, returning a new date.
  ///
  /// Delegates to [DateTime] for the calendar arithmetic because month lengths
  /// and leap years are exactly the kind of edge case that should not be
  /// hand-rolled, then converts back to the zone-free representation.
  /// Returns null when the result would fall outside `[1-01-01, 9999-12-31]`.
  LocalDate? addDays(int days) {
    final shifted = toUtcDateTime().add(Duration(days: days));
    final result = LocalDate.tryCreate(
      shifted.year,
      shifted.month,
      shifted.day,
    );
    return result;
  }

  /// Adds [months] calendar months, clamping the day to the target month's end.
  ///
  /// `2026-01-31` plus one month yields `2026-02-28`, not an invalid
  /// `2026-02-31`. This is the behaviour a "next month" button needs.
  LocalDate? addMonths(int months) {
    if (months == 0) return this;
    // Total months since year 1, so the arithmetic is a single division.
    final totalMonths = (year * 12 + (month - 1)) + months;
    if (totalMonths < 12) return null; // would go before year 1
    final newYear = totalMonths ~/ 12;
    final newMonth = totalMonths % 12 + 1;
    if (newYear > 9999) return null;
    final clampedDay = day > _daysInMonth(newYear, newMonth)
        ? _daysInMonth(newYear, newMonth)
        : day;
    return LocalDate.tryCreate(newYear, newMonth, clampedDay);
  }

  /// The day of the week, where 1 is Monday and 7 is Sunday (ISO-8601).
  ///
  /// Dart's `DateTime.weekday` already uses this convention; the mapping is
  /// re-derived here from the UTC calendar so the result cannot depend on the
  /// device's local time zone.
  int get isoWeekday => toUtcDateTime().weekday;

  /// The first day of this date's month.
  LocalDate get firstDayOfMonth => LocalDate(year, month, 1);

  /// The last day of this date's month.
  LocalDate get lastDayOfMonth =>
      LocalDate(year, month, _daysInMonth(year, month));

  /// True when this date falls in the same month and year as [other].
  bool isSameMonthAs(LocalDate other) =>
      year == other.year && month == other.month;

  /// True when this is strictly before [other] chronologically.
  bool isBefore(LocalDate other) => value < other.value;

  /// True when this is strictly after [other] chronologically.
  bool isAfter(LocalDate other) => value > other.value;

  /// Whole days from [other] to this date; negative when this is earlier.
  ///
  /// Computed on normalised UTC midnights so a DST transition in between cannot
  /// round the difference to ±1 day.
  int daysSince(LocalDate other) =>
      toUtcDateTime().difference(other.toUtcDateTime()).inDays;

  /// Chronological comparison, consistent with the packed-integer ordering.
  @override
  int compareTo(LocalDate other) => value.compareTo(other.value);

  bool operator <(LocalDate other) => value < other.value;
  bool operator <=(LocalDate other) => value <= other.value;
  bool operator >(LocalDate other) => value > other.value;
  bool operator >=(LocalDate other) => value >= other.value;

  /// Equality by calendar day.
  @override
  bool operator ==(Object other) => other is LocalDate && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// ISO-8601 representation, `2026-10-10`.
  ///
  /// Debug/serialisation only — user-facing dates go through `intl` with the
  /// active locale (docs/Conventions.md §5).
  @override
  String toString() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static int _daysInMonth(int year, int month) => switch (month) {
    1 || 3 || 5 || 7 || 8 || 10 || 12 => 31,
    4 || 6 || 9 || 11 => 30,
    2 => isLeapYear(year) ? 29 : 28,
    _ => 0,
  };
}

/// Thrown when a [LocalDate] is constructed from an impossible calendar date.
///
/// A programmer error when raised by the throwing constructor — untrusted input
/// should go through `LocalDate.tryCreate`.
final class InvalidDateError extends Error {
  InvalidDateError(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  @override
  String toString() =>
      'InvalidDateError: $year-$month-$day is not a valid calendar date.';
}
