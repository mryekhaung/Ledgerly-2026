import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/presentation/providers/calendar_notifier.dart';

/// `CalendarState` is pure Dart, so the month-arithmetic and day-clamping rules
/// are tested here rather than through a widget tree — the widget tests then
/// only have to prove that a gesture or a tap reaches this logic.
///
/// `isTodaySelected` is passed explicitly instead of computed, so these tests do
/// not depend on the real clock and will not fail at midnight or on New Year's
/// Eve.
void main() {
  CalendarState stateFor(LocalDate month, LocalDate selected) => CalendarState(
    visibleMonth: month.firstDayOfMonth,
    selectedDay: selected,
    isTodaySelected: false,
  );

  group('withMonth', () {
    test('should_move_the_visible_month_and_keep_the_day_of_month', () {
      final state = stateFor(LocalDate(2026, 3, 15), LocalDate(2026, 3, 15));

      final moved = state.withMonth(LocalDate(2026, 4, 1));

      expect(moved.visibleMonth, LocalDate(2026, 4, 1));
      expect(moved.selectedDay, LocalDate(2026, 4, 15));
    });

    test('should_clamp_a_31st_into_a_shorter_month', () {
      // 31 March -> April has 30 days. This is the case that throws if the day
      // is carried over naively.
      final state = stateFor(LocalDate(2026, 3, 31), LocalDate(2026, 3, 31));

      final moved = state.withMonth(LocalDate(2026, 4, 1));

      expect(moved.selectedDay, LocalDate(2026, 4, 30));
    });

    test('should_clamp_a_31st_into_february_in_a_non_leap_year', () {
      final state = stateFor(LocalDate(2026, 1, 31), LocalDate(2026, 1, 31));

      final moved = state.withMonth(LocalDate(2026, 2, 1));

      expect(moved.selectedDay, LocalDate(2026, 2, 28));
    });

    test('should_clamp_a_31st_into_february_29_in_a_leap_year', () {
      final state = stateFor(LocalDate(2024, 1, 31), LocalDate(2024, 1, 31));

      final moved = state.withMonth(LocalDate(2024, 2, 1));

      expect(moved.selectedDay, LocalDate(2024, 2, 29));
    });

    test('should_cross_a_year_boundary', () {
      final state = stateFor(LocalDate(2026, 12, 10), LocalDate(2026, 12, 10));

      final moved = state.withMonth(LocalDate(2027, 1, 1));

      expect(moved.visibleMonth, LocalDate(2027, 1, 1));
      expect(moved.selectedDay, LocalDate(2027, 1, 10));
    });

    test('should_jump_backwards_across_a_year_boundary', () {
      final state = stateFor(LocalDate(2026, 1, 10), LocalDate(2026, 1, 10));

      final moved = state.withMonth(LocalDate(2025, 12, 1));

      expect(moved.visibleMonth, LocalDate(2025, 12, 1));
      expect(moved.selectedDay, LocalDate(2025, 12, 10));
    });

    test('should_accept_a_mid_month_date_as_the_month', () {
      // The picker returns a first-of-month, but `withMonth` must not depend on
      // that: it reads only year and month, so any day works.
      final state = stateFor(LocalDate(2026, 3, 5), LocalDate(2026, 3, 5));

      final moved = state.withMonth(LocalDate(2026, 7, 19));

      expect(moved.visibleMonth, LocalDate(2026, 7, 19));
      expect(moved.selectedDay, LocalDate(2026, 7, 5));
    });
  });

  group('addMonths on LocalDate', () {
    test('should_return_null_past_the_maximum_year', () {
      final end = LocalDate(9999, 12, 1);

      expect(end.addMonths(1), isNull);
    });

    test('should_return_null_before_the_minimum_year', () {
      final start = LocalDate(1, 1, 1);

      expect(start.addMonths(-1), isNull);
    });
  });

  group('canGoToToday', () {
    test('should_be_true_when_a_past_day_is_selected', () {
      final state = CalendarState(
        visibleMonth: LocalDate(2020, 1, 1),
        selectedDay: LocalDate(2020, 1, 1),
        isTodaySelected: false,
      );

      expect(state.canGoToToday, isTrue);
    });

    test('should_be_false_when_today_is_already_selected', () {
      final today = LocalDate.fromDateTime(DateTime.now());
      final state = CalendarState(
        visibleMonth: today.firstDayOfMonth,
        selectedDay: today,
        isTodaySelected: true,
      );

      expect(state.canGoToToday, isFalse);
    });
  });
}
