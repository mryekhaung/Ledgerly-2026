/// Tests for the budget-period domain (docs/DataModel.md §8).
///
/// Covers every case the spec calls out: the startDay-10 examples, the year
/// boundary, February in leap and non-leap years, `startDay == 1` degenerating
/// to a calendar month, `startDay == 28`, the `previous(next(p)) == p` round
/// trip over many dates, and the guarantee that a boundary-day transaction
/// lands in exactly one period.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/period/period_calculator.dart';
import 'package:ledgerly/core/utils/local_date.dart';

void main() {
  group('PeriodCalculator(startDay: 10) — the spec examples', () {
    final calc = PeriodCalculator(10);

    test('Oct 9 sits in the previous month block (Sep 10 – Oct 9)', () {
      final p = calc.containing(LocalDate(2026, 10, 9));
      expect(p.start, LocalDate(2026, 9, 10));
      expect(p.end, LocalDate(2026, 10, 9));
    });

    test('Oct 10 starts a new period (Oct 10 – Nov 9)', () {
      final p = calc.containing(LocalDate(2026, 10, 10));
      expect(p.start, LocalDate(2026, 10, 10));
      expect(p.end, LocalDate(2026, 11, 9));
    });

    test('Dec 31 is in Dec 10 – Jan 9 (same calendar month as start)', () {
      final p = calc.containing(LocalDate(2026, 12, 31));
      expect(p.start, LocalDate(2026, 12, 10));
      expect(p.end, LocalDate(2027, 1, 9));
    });

    test('Jan 5 crosses back to the prior year block (Dec 10 – Jan 9)', () {
      final p = calc.containing(LocalDate(2027, 1, 5));
      expect(p.start, LocalDate(2026, 12, 10));
      expect(p.end, LocalDate(2027, 1, 9));
    });

    test('period id is yyyy-MM of the start date', () {
      expect(calc.containing(LocalDate(2026, 10, 10)).id, '2026-10');
      expect(calc.containing(LocalDate(2026, 12, 31)).id, '2026-12');
      expect(calc.containing(LocalDate(2027, 1, 5)).id, '2026-12');
    });
  });

  group('February across leap and non-leap years (startDay: 10)', () {
    test('Feb 15 in a leap year (2024) → Feb 10 – Mar 9', () {
      final calc = PeriodCalculator(10);
      final p = calc.containing(LocalDate(2024, 2, 15));
      expect(p.start, LocalDate(2024, 2, 10));
      expect(p.end, LocalDate(2024, 3, 9));
    });

    test('Feb 15 in a non-leap year (2023) → Feb 10 – Mar 9', () {
      final calc = PeriodCalculator(10);
      final p = calc.containing(LocalDate(2023, 2, 15));
      expect(p.start, LocalDate(2023, 2, 10));
      expect(p.end, LocalDate(2023, 3, 9));
    });

    test('Feb 29 only exists in a leap year and is contained', () {
      // 2024 is a leap year; 2023 is not, so Feb 29 cannot be constructed.
      expect(LocalDate.tryCreate(2023, 2, 29), isNull);
      final calc = PeriodCalculator(10);
      final p = calc.containing(LocalDate(2024, 2, 29));
      expect(p.start, LocalDate(2024, 2, 10));
      expect(p.end, LocalDate(2024, 3, 9));
    });

    test('a period ending in February has the right day count either way', () {
      final calc = PeriodCalculator(10);
      // Jan 10 – Feb 9: the trailing February run is 9 days in both years.
      final leap = calc.containing(LocalDate(2024, 1, 15));
      final nonLeap = calc.containing(LocalDate(2023, 1, 15));
      expect(leap.length, 31);
      expect(nonLeap.length, 31);
    });
  });

  group('startDay == 1 is exactly a calendar month', () {
    final calc = PeriodCalculator(1);

    test('Oct 15 → Oct 1 – Oct 31', () {
      final p = calc.containing(LocalDate(2026, 10, 15));
      expect(p.start, LocalDate(2026, 10, 1));
      expect(p.end, LocalDate(2026, 10, 31));
    });

    test('Oct 31 still in October', () {
      final p = calc.containing(LocalDate(2026, 10, 31));
      expect(p.start, LocalDate(2026, 10, 1));
      expect(p.end, LocalDate(2026, 10, 31));
    });

    test('Nov 1 rolls to a new calendar month', () {
      final p = calc.containing(LocalDate(2026, 11, 1));
      expect(p.start, LocalDate(2026, 11, 1));
      expect(p.end, LocalDate(2026, 11, 30));
    });

    test('February length respects leap years', () {
      expect(calc.containing(LocalDate(2024, 2, 1)).length, 29);
      expect(calc.containing(LocalDate(2023, 2, 1)).length, 28);
    });
  });

  group('startDay == 28', () {
    final calc = PeriodCalculator(28);

    test('Jan 28 starts a period ending Feb 27', () {
      final p = calc.containing(LocalDate(2026, 1, 28));
      expect(p.start, LocalDate(2026, 1, 28));
      expect(p.end, LocalDate(2026, 2, 27));
    });

    test('Jan 27 falls in the prior block (Dec 28 – Jan 27)', () {
      final p = calc.containing(LocalDate(2026, 1, 27));
      expect(p.start, LocalDate(2025, 12, 28));
      expect(p.end, LocalDate(2026, 1, 27));
    });

    test('Feb 28 (leap) starts its own period (Feb 28 – Mar 27)', () {
      final p = calc.containing(LocalDate(2024, 2, 28));
      expect(p.start, LocalDate(2024, 2, 28));
      expect(p.end, LocalDate(2024, 3, 27));
    });
  });

  group('next / previous are mutual inverses', () {
    final calc = PeriodCalculator(10);

    test('previous(next(p)) == p for 100 spread-out dates', () {
      // Deterministic sweep from 2020-01-01 to 2030-12-31, stepping ~40 days
      // so the sample hits every month, both February shapes, and year ends.
      var date = LocalDate(2020, 1, 1);
      final last = LocalDate(2030, 12, 31);
      var checked = 0;
      while (!date.isAfter(last)) {
        final p = calc.containing(date);
        expect(calc.previous(calc.next(p)), p, reason: 'at $date');
        expect(calc.next(calc.previous(p)), p, reason: 'at $date');
        date = date.addDays(40)!;
        checked++;
      }
      expect(checked, greaterThanOrEqualTo(100));
    });

    test('next advances by exactly one period', () {
      final p = calc.containing(LocalDate(2026, 10, 15));
      final n = calc.next(p);
      expect(n.start, LocalDate(2026, 11, 10));
      expect(n.end, LocalDate(2026, 12, 9));
    });
  });

  group('boundary days land in exactly one period', () {
    final calc = PeriodCalculator(10);

    test('a period start/end is contained only by that period', () {
      final p = calc.containing(LocalDate(2026, 10, 15)); // Oct 10 – Nov 9
      expect(p.contains(p.start), isTrue);
      expect(p.contains(p.end), isTrue);

      // The start is not in the next period, the end is not in the previous.
      final next = calc.next(p);
      final previous = calc.previous(p);
      expect(next.contains(p.start), isFalse);
      expect(previous.contains(p.end), isFalse);
    });

    test('the day before the start belongs to the previous period', () {
      final p = calc.containing(LocalDate(2026, 10, 15)); // Oct 10 – Nov 9
      final dayBefore = p.start.addDays(-1)!; // Oct 9
      expect(calc.containing(dayBefore), calc.previous(p));
      expect(calc.containing(dayBefore), isNot(p));
    });

    test('the day after the end belongs to the next period', () {
      final p = calc.containing(LocalDate(2026, 10, 15)); // Oct 10 – Nov 9
      final dayAfter = p.end.addDays(1)!; // Nov 10
      expect(calc.containing(dayAfter), calc.next(p));
      expect(calc.containing(dayAfter), isNot(p));
    });
  });
}
