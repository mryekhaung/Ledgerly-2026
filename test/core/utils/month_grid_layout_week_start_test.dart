import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/utils/month_grid_layout.dart';

/// `MonthGridLayout` with a configurable week start.
///
/// The Monday-first behaviour was already covered; these cases add the
/// Sunday-first rotation the Settings page now offers. The rotation is the easy
/// part to get subtly wrong — a Sunday-first grid whose 1st falls on a Sunday
/// must have **zero** leading blanks, and one whose 1st falls on a Monday must
/// have six.
void main() {
  group('GridWeekStart', () {
    test('maps to the matching ISO weekday', () {
      expect(GridWeekStart.monday.isoWeekday, 1);
      expect(GridWeekStart.sunday.isoWeekday, 7);
    });
  });

  group('leadingBlanks with Monday-first (the default)', () {
    test('a Monday 1st needs no blanks', () {
      // 2026-06-01 is a Monday.
      expect(MonthGridLayout.leadingBlanks(LocalDate(2026, 6, 1)), 0);
    });

    test('a Sunday 1st needs six blanks', () {
      // 2026-11-01 is a Sunday.
      expect(MonthGridLayout.leadingBlanks(LocalDate(2026, 11, 1)), 6);
    });

    test('the default equals an explicit monday', () {
      final month = LocalDate(2026, 11, 1);
      expect(
        MonthGridLayout.leadingBlanks(month),
        MonthGridLayout.leadingBlanks(month, weekStart: GridWeekStart.monday),
      );
    });
  });

  group('leadingBlanks with Sunday-first', () {
    test('a Sunday 1st needs no blanks', () {
      expect(
        MonthGridLayout.leadingBlanks(
          LocalDate(2026, 11, 1),
          weekStart: GridWeekStart.sunday,
        ),
        0,
      );
    });

    test('a Monday 1st needs one blank', () {
      // 2026-06-01 is a Monday (ISO weekday 1) → only Sunday precedes it, so a
      // Sunday-first grid leaves exactly one leading blank.
      expect(
        MonthGridLayout.leadingBlanks(
          LocalDate(2026, 6, 1),
          weekStart: GridWeekStart.sunday,
        ),
        1,
      );
    });

    test('a Saturday 1st needs six blanks', () {
      // 2026-08-01 is a Saturday (ISO weekday 6) → 6 blanks in a Sunday grid.
      expect(
        MonthGridLayout.leadingBlanks(
          LocalDate(2026, 8, 1),
          weekStart: GridWeekStart.sunday,
        ),
        6,
      );
    });

    test('rotates the Monday-first offset by exactly one for every day', () {
      // Sunday-first is Monday-first shifted one forward, wrapped: Monday(0) →
      // 1, Tuesday(1) → 2, …, Sunday(6) → 0.
      for (var day = 1; day <= 28; day++) {
        final month = LocalDate(2026, 1, day);
        final monday = MonthGridLayout.leadingBlanks(month);
        final sunday = MonthGridLayout.leadingBlanks(
          month,
          weekStart: GridWeekStart.sunday,
        );
        expect(
          sunday,
          (monday + 1) % 7,
          reason: 'rotation wrong for day $day (monday=$monday)',
        );
      }
    });
  });

  group('cells with Sunday-first', () {
    test('the 1st lands in the first column when it is a Sunday', () {
      final cells = MonthGridLayout.cells(
        LocalDate(2026, 11, 1),
        weekStart: GridWeekStart.sunday,
      );
      expect(cells.first, LocalDate(2026, 11, 1));
    });

    test('every day of the month still appears exactly once', () {
      final month = LocalDate(2026, 11, 1);
      final cells = MonthGridLayout.cells(
        month,
        weekStart: GridWeekStart.sunday,
      );

      final days = cells.whereType<LocalDate>().toList();
      expect(days.length, LocalDate.daysInMonth(2026, 11));
      for (var day = 1; day <= 30; day++) {
        expect(days.contains(LocalDate(2026, 11, day)), isTrue);
      }
    });

    test('the cell count stays a whole number of weeks', () {
      for (var monthNumber = 1; monthNumber <= 12; monthNumber++) {
        final month = LocalDate(2026, monthNumber, 1);
        for (final start in GridWeekStart.values) {
          expect(
            MonthGridLayout.cellCount(month, weekStart: start) %
                MonthGridLayout.daysPerWeek,
            0,
          );
        }
      }
    });
  });
}
