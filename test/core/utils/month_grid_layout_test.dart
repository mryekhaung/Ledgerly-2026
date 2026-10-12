import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/utils/month_grid_layout.dart';

void main() {
  group('MonthGridLayout.leadingBlanks', () {
    test('a month starting on Monday needs no padding', () {
      // 2026-06-01 is a Monday.
      expect(MonthGridLayout.leadingBlanks(LocalDate(2026, 6, 1)), 0);
    });

    test('a month starting on Sunday needs six blanks', () {
      // 2026-02-01 is a Sunday — the worst case, and the one that pushes a
      // 28-day February onto a fifth row.
      expect(MonthGridLayout.leadingBlanks(LocalDate(2026, 2, 1)), 6);
    });

    test('a month starting mid-week pads to its weekday', () {
      // 2026-10-01 is a Thursday → ISO weekday 4 → three blanks.
      expect(MonthGridLayout.leadingBlanks(LocalDate(2026, 10, 1)), 3);
    });

    test('is always within a week', () {
      for (var month = 1; month <= 12; month++) {
        final blanks = MonthGridLayout.leadingBlanks(LocalDate(2026, month, 1));
        expect(blanks, inInclusiveRange(0, 6));
      }
    });
  });

  group('MonthGridLayout.cellCount', () {
    test('is always a whole number of weeks', () {
      for (var year = 2025; year <= 2027; year++) {
        for (var month = 1; month <= 12; month++) {
          final count = MonthGridLayout.cellCount(LocalDate(year, month, 1));
          expect(count % MonthGridLayout.daysPerWeek, 0);
        }
      }
    });

    test('never truncates a partly-filled final week', () {
      // 2026-08 has 31 days starting on a Saturday: 5 blanks + 31 = 36, which
      // must round up to 42 cells and not down to 35.
      final august = LocalDate(2026, 8, 1);
      expect(MonthGridLayout.leadingBlanks(august), 5);
      expect(MonthGridLayout.cellCount(august), 42);
    });

    test('exactly fills when the month ends on a Sunday', () {
      // 2026-02 has 28 days starting on a Sunday: 6 + 28 = 34 → 35 cells.
      expect(MonthGridLayout.cellCount(LocalDate(2026, 2, 1)), 35);
    });

    test('a 28-day February starting on Monday is the minimum, four rows', () {
      // 2027-02: 28 days starting Monday → exactly 28 cells, 4 rows.
      expect(MonthGridLayout.cellCount(LocalDate(2027, 2, 1)), 28);
    });

    test('a 31-day month needs six rows only in the Sunday-start case', () {
      // 31 days starting Sunday → 6 + 31 = 37 → 42 cells (six rows).
      expect(MonthGridLayout.cellCount(LocalDate(2026, 3, 1)), 42);
    });
  });

  group('MonthGridLayout.dayAt', () {
    test('the first blank cell is not a day', () {
      expect(MonthGridLayout.dayAt(LocalDate(2026, 2, 1), 0), isNull);
      expect(MonthGridLayout.dayAt(LocalDate(2026, 2, 1), 5), isNull);
    });

    test('day 1 lands immediately after the blanks', () {
      expect(
        MonthGridLayout.dayAt(LocalDate(2026, 2, 1), 6),
        LocalDate(2026, 2, 1),
      );
    });

    test('the last day is at blank + daysInMonth - 1', () {
      final month = LocalDate(2026, 2, 1);
      final index = MonthGridLayout.leadingBlanks(month) + 28 - 1;
      expect(MonthGridLayout.dayAt(month, index), LocalDate(2026, 2, 28));
    });

    test('a trailing cell is not a day', () {
      // 2026-02's 35 cells hold 6 blanks + 28 days + 1 trailing blank.
      expect(MonthGridLayout.dayAt(LocalDate(2026, 2, 1), 34), isNull);
    });

    test('never invents a day in a 31-day month', () {
      final month = LocalDate(2026, 10, 1);
      for (var index = 0; index < MonthGridLayout.cellCount(month); index++) {
        final day = MonthGridLayout.dayAt(month, index);
        if (day != null) {
          expect(day.month, 10);
          expect(day.day, inInclusiveRange(1, 31));
        }
      }
    });

    test('a leap-year February reaches the 29th', () {
      final month = LocalDate(2024, 2, 1);
      final cells = MonthGridLayout.cells(month);
      expect(cells.contains(LocalDate(2024, 2, 29)), isTrue);
      // Compared as packed ints: constructing `LocalDate(2024, 2, 30)` would
      // itself throw, which is the point — no cell can ever produce one.
      expect(
        cells.whereType<LocalDate>().every((d) => d.value != 20240230),
        isTrue,
      );
      expect(cells.whereType<LocalDate>().length, 29);
    });
  });

  group('MonthGridLayout.cells', () {
    test('a full year of grids holds every day exactly once', () {
      for (var month = 1; month <= 12; month++) {
        final first = LocalDate(2026, month, 1);
        final days = MonthGridLayout.cells(first)
            .whereType<LocalDate>()
            .toList();

        expect(
          days.length,
          LocalDate.daysInMonth(2026, month),
          reason: 'month $month day count',
        );
        expect(days.first, first, reason: 'month $month starts at day 1');
        expect(
          days.last,
          first.lastDayOfMonth,
          reason: 'month $month ends at its last day',
        );
        // No duplicates and strictly increasing — the grid never repeats a date.
        for (var index = 1; index < days.length; index++) {
          expect(days[index].value, greaterThan(days[index - 1].value));
        }
      }
    });

    test('every day in the year appears in exactly one month grid', () {
      final seen = <int, int>{};
      for (var month = 1; month <= 12; month++) {
        for (final day in MonthGridLayout.cells(
          LocalDate(2026, month, 1),
        ).whereType<LocalDate>()) {
          seen.update(day.value, (count) => count + 1, ifAbsent: () => 1);
        }
      }
      // 2026 is not a leap year, so 365 distinct days, each seen once.
      expect(seen.length, 365);
      expect(seen.values.every((count) => count == 1), isTrue);
    });

    test('nulls only ever form a contiguous run at each end', () {
      for (var month = 1; month <= 12; month++) {
        final cells = MonthGridLayout.cells(LocalDate(2026, month, 1));
        final firstDay = cells.indexOf(
          cells.firstWhere((cell) => cell != null),
        );
        final lastDay = cells.lastIndexOf(
          cells.lastWhere((cell) => cell != null),
        );
        for (var index = firstDay; index <= lastDay; index++) {
          expect(cells[index], isNotNull, reason: 'month $month cell $index');
        }
      }
    });
  });
}
