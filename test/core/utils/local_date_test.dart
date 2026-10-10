import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/local_date.dart';

/// `LocalDate` exists to stop time zones and DST from moving a transaction to
/// the wrong day. The tests below pin the parts that are easy to get subtly
/// wrong: leap years, month-length clamping, and the packed-integer round trip.
void main() {
  group('LocalDate construction', () {
    test('should_expose_components_when_created_from_parts', () {
      final date = LocalDate(2026, 10, 10);

      expect(date.year, 2026);
      expect(date.month, 10);
      expect(date.day, 10);
    });

    test('should_pack_into_yyyymmdd_when_created', () {
      expect(LocalDate(2026, 10, 10).value, 20261010);
      expect(LocalDate(2026, 1, 5).value, 20260105);
      expect(LocalDate(9999, 12, 31).value, 99991231);
      expect(LocalDate(1, 1, 1).value, 10101);
    });

    test('should_throw_when_created_from_an_impossible_date', () {
      expect(() => LocalDate(2026, 2, 30), throwsA(isA<InvalidDateError>()));
      expect(() => LocalDate(2026, 13, 1), throwsA(isA<InvalidDateError>()));
      expect(() => LocalDate(2026, 0, 1), throwsA(isA<InvalidDateError>()));
      expect(() => LocalDate(0, 1, 1), throwsA(isA<InvalidDateError>()));
    });
  });

  group('LocalDate.tryCreate validation', () {
    test('should_return_a_date_when_input_is_valid', () {
      expect(LocalDate.tryCreate(2026, 10, 10), LocalDate(2026, 10, 10));
    });

    test('should_return_null_when_day_exceeds_month_length', () {
      expect(LocalDate.tryCreate(2026, 4, 31), isNull);
      expect(LocalDate.tryCreate(2026, 6, 31), isNull);
      expect(LocalDate.tryCreate(2026, 9, 31), isNull);
      expect(LocalDate.tryCreate(2026, 11, 31), isNull);
      expect(LocalDate.tryCreate(2026, 2, 30), isNull);
    });

    test('should_return_null_when_month_is_out_of_range', () {
      expect(LocalDate.tryCreate(2026, 0, 1), isNull);
      expect(LocalDate.tryCreate(2026, 13, 1), isNull);
      expect(LocalDate.tryCreate(2026, -1, 1), isNull);
    });

    test('should_return_null_when_day_is_zero_or_negative', () {
      expect(LocalDate.tryCreate(2026, 1, 0), isNull);
      expect(LocalDate.tryCreate(2026, 1, -1), isNull);
    });

    test('should_return_null_when_year_is_outside_representable_range', () {
      expect(LocalDate.tryCreate(0, 1, 1), isNull);
      expect(LocalDate.tryCreate(-1, 1, 1), isNull);
      expect(LocalDate.tryCreate(10000, 1, 1), isNull);
      expect(LocalDate.tryCreate(9999, 12, 31), isNotNull);
    });
  });

  group('LocalDate leap years', () {
    test('should_accept_feb_29_when_year_is_divisible_by_four', () {
      expect(LocalDate.tryCreate(2024, 2, 29), isNotNull);
      expect(LocalDate.tryCreate(2028, 2, 29), isNotNull);
    });

    test('should_reject_feb_29_when_year_is_not_a_leap_year', () {
      expect(LocalDate.tryCreate(2023, 2, 29), isNull);
      expect(LocalDate.tryCreate(2026, 2, 29), isNull);
    });

    test('should_accept_feb_29_when_century_is_divisible_by_400', () {
      // The classic rule: 2000 is a leap year, 1900 is not.
      expect(LocalDate.isLeapYear(2000), isTrue);
      expect(LocalDate.tryCreate(2000, 2, 29), isNotNull);
    });

    test('should_reject_feb_29_when_century_is_not_divisible_by_400', () {
      expect(LocalDate.isLeapYear(1900), isFalse);
      expect(LocalDate.tryCreate(1900, 2, 29), isNull);
      expect(LocalDate.isLeapYear(2100), isFalse);
    });

    test('should_report_february_length_by_leap_year', () {
      expect(LocalDate.daysInMonth(2024, 2), 29);
      expect(LocalDate.daysInMonth(2026, 2), 28);
    });

    test('should_report_month_length_for_every_month', () {
      expect(LocalDate.daysInMonth(2026, 1), 31);
      expect(LocalDate.daysInMonth(2026, 2), 28);
      expect(LocalDate.daysInMonth(2026, 3), 31);
      expect(LocalDate.daysInMonth(2026, 4), 30);
      expect(LocalDate.daysInMonth(2026, 5), 31);
      expect(LocalDate.daysInMonth(2026, 6), 30);
      expect(LocalDate.daysInMonth(2026, 7), 31);
      expect(LocalDate.daysInMonth(2026, 8), 31);
      expect(LocalDate.daysInMonth(2026, 9), 30);
      expect(LocalDate.daysInMonth(2026, 10), 31);
      expect(LocalDate.daysInMonth(2026, 11), 30);
      expect(LocalDate.daysInMonth(2026, 12), 31);
    });

    test('should_throw_when_asked_for_an_invalid_month_length', () {
      expect(() => LocalDate.daysInMonth(2026, 0), throwsArgumentError);
      expect(() => LocalDate.daysInMonth(2026, 13), throwsArgumentError);
    });
  });

  group('LocalDate.fromPacked', () {
    test('should_round_trip_when_value_is_valid', () {
      for (final date in [
        LocalDate(2026, 10, 10),
        LocalDate(2024, 2, 29),
        LocalDate(1, 1, 1),
        LocalDate(9999, 12, 31),
      ]) {
        expect(LocalDate.fromPacked(date.value), date);
      }
    });

    test('should_return_null_when_packed_date_is_impossible', () {
      // 2026-02-30 is not a real date, so it must not roll forward to March 2.
      expect(LocalDate.fromPacked(20260230), isNull);
      expect(LocalDate.fromPacked(20261301), isNull);
      expect(LocalDate.fromPacked(20260010), isNull);
    });

    test('should_return_null_when_packed_value_is_out_of_range', () {
      expect(LocalDate.fromPacked(0), isNull);
      expect(LocalDate.fromPacked(999999), isNull);
      expect(LocalDate.fromPacked(10000100), isNull);
      expect(LocalDate.fromPacked(99991232), isNull);
      expect(LocalDate.fromPacked(-20261010), isNull);
    });

    test('should_accept_the_lower_boundary_of_the_representable_range', () {
      expect(LocalDate.fromPacked(10000101), LocalDate(1000, 1, 1));
    });
  });

  group('LocalDate from DateTime', () {
    test('should_discard_time_when_converting_from_local_datetime', () {
      final date = LocalDate.fromDateTime(DateTime(2026, 10, 10, 23, 59, 59));

      expect(date, LocalDate(2026, 10, 10));
    });

    test('should_use_utc_calendar_day_when_converting_from_utc', () {
      // An instant late in the day UTC is still that day in UTC even if the
      // device's zone would render it as the next day.
      final instant = DateTime.utc(2026, 10, 10, 23, 30);
      expect(LocalDate.fromUtc(instant), LocalDate(2026, 10, 10));
    });

    test('should_round_trip_through_datetime_when_time_is_midnight', () {
      final date = LocalDate(2026, 10, 10);

      expect(LocalDate.fromDateTime(date.toDateTime()), date);
      expect(LocalDate.fromUtc(date.toUtcDateTime()), date);
    });

    test('should_produce_a_midnight_datetime_when_converting', () {
      final dateTime = LocalDate(2026, 10, 10).toDateTime();

      expect(dateTime.hour, 0);
      expect(dateTime.minute, 0);
      expect(dateTime.second, 0);
      expect(dateTime.millisecond, 0);
    });
  });

  group('LocalDate.addDays', () {
    test('should_move_within_a_month_when_no_boundary_is_crossed', () {
      expect(LocalDate(2026, 10, 10).addDays(5), LocalDate(2026, 10, 15));
    });

    test('should_roll_over_to_the_next_month_when_crossing_a_boundary', () {
      expect(LocalDate(2026, 10, 31).addDays(1), LocalDate(2026, 11, 1));
    });

    test('should_roll_over_to_the_next_year_when_crossing_december', () {
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
    });

    test('should_roll_backwards_when_crossing_a_month_start', () {
      expect(LocalDate(2026, 1, 1).addDays(-1), LocalDate(2025, 12, 31));
    });

    test('should_land_on_feb_29_when_adding_across_a_leap_day', () {
      expect(LocalDate(2024, 2, 28).addDays(1), LocalDate(2024, 2, 29));
    });

    test('should_skip_feb_29_when_the_year_is_not_leap', () {
      expect(LocalDate(2026, 2, 28).addDays(1), LocalDate(2026, 3, 1));
    });

    test('should_return_the_same_date_when_adding_zero', () {
      final date = LocalDate(2026, 10, 10);

      expect(date.addDays(0), date);
    });

    test('should_return_null_when_result_exceeds_the_representable_range', () {
      expect(LocalDate(9999, 12, 31).addDays(1), isNull);
      expect(LocalDate(1, 1, 1).addDays(-1), isNull);
    });
  });

  group('LocalDate.addMonths', () {
    test('should_move_a_month_when_the_day_exists_in_the_target', () {
      expect(LocalDate(2026, 10, 10).addMonths(1), LocalDate(2026, 11, 10));
    });

    test('should_clamp_to_the_last_day_when_target_month_is_shorter', () {
      // The "next month" button must not produce an invalid Feb 31.
      expect(LocalDate(2026, 1, 31).addMonths(1), LocalDate(2026, 2, 28));
      expect(LocalDate(2026, 3, 31).addMonths(-1), LocalDate(2026, 2, 28));
    });

    test('should_clamp_to_feb_29_when_target_year_is_leap', () {
      expect(LocalDate(2024, 1, 31).addMonths(1), LocalDate(2024, 2, 29));
    });

    test('should_carry_into_the_next_year_when_crossing_december', () {
      expect(LocalDate(2026, 12, 15).addMonths(1), LocalDate(2027, 1, 15));
    });

    test('should_carry_into_the_previous_year_when_going_back', () {
      expect(LocalDate(2026, 1, 15).addMonths(-1), LocalDate(2025, 12, 15));
    });

    test('should_move_whole_years_when_months_is_a_multiple_of_twelve', () {
      expect(LocalDate(2026, 10, 10).addMonths(12), LocalDate(2027, 10, 10));
      expect(LocalDate(2026, 10, 10).addMonths(-12), LocalDate(2025, 10, 10));
    });

    test('should_clamp_when_a_leap_day_moves_into_a_common_year', () {
      expect(LocalDate(2024, 2, 29).addMonths(12), LocalDate(2025, 2, 28));
    });

    test('should_return_the_same_date_when_adding_zero_months', () {
      final date = LocalDate(2026, 10, 10);

      expect(date.addMonths(0), date);
    });

    test('should_return_null_when_result_exceeds_the_representable_range', () {
      expect(LocalDate(9999, 6, 1).addMonths(12), isNull);
      expect(LocalDate(1, 6, 1).addMonths(-12), isNull);
    });
  });

  group('LocalDate month boundaries', () {
    test('should_return_the_first_day_when_asked', () {
      expect(LocalDate(2026, 10, 10).firstDayOfMonth, LocalDate(2026, 10, 1));
    });

    test('should_return_the_last_day_when_asked', () {
      expect(LocalDate(2026, 10, 10).lastDayOfMonth, LocalDate(2026, 10, 31));
      expect(LocalDate(2026, 2, 10).lastDayOfMonth, LocalDate(2026, 2, 28));
      expect(LocalDate(2024, 2, 10).lastDayOfMonth, LocalDate(2024, 2, 29));
    });

    test('should_be_idempotent_when_already_the_first_or_last_day', () {
      final first = LocalDate(2026, 10, 1);

      expect(first.firstDayOfMonth, first);
      expect(first.lastDayOfMonth.lastDayOfMonth, LocalDate(2026, 10, 31));
    });
  });

  group('LocalDate comparison', () {
    test('should_compare_chronologically_when_ordered', () {
      final earlier = LocalDate(2026, 10, 9);
      final later = LocalDate(2026, 10, 10);

      expect(earlier.compareTo(later), lessThan(0));
      expect(later.compareTo(earlier), greaterThan(0));
      expect(earlier < later, isTrue);
      expect(later > earlier, isTrue);
      expect(earlier <= later, isTrue);
      expect(later >= earlier, isTrue);
    });

    test('should_treat_equal_dates_as_equal_when_compared', () {
      final a = LocalDate(2026, 10, 10);
      final b = LocalDate(2026, 10, 10);

      expect(a.compareTo(b), 0);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a <= b, isTrue);
      expect(a >= b, isTrue);
    });

    test('should_order_across_years_when_dates_span_a_boundary', () {
      expect(LocalDate(2025, 12, 31) < LocalDate(2026, 1, 1), isTrue);
    });

    test('should_report_before_and_after_correctly', () {
      final a = LocalDate(2026, 1, 1);
      final b = LocalDate(2026, 12, 31);

      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.isBefore(a), isFalse);
      expect(a.isAfter(a), isFalse);
    });

    test('should_distinguish_months_when_years_match', () {
      expect(
        LocalDate(2026, 10, 1).isSameMonthAs(LocalDate(2026, 10, 31)),
        isTrue,
      );
      expect(
        LocalDate(2026, 10, 1).isSameMonthAs(LocalDate(2026, 11, 1)),
        isFalse,
      );
      expect(
        LocalDate(2026, 10, 1).isSameMonthAs(LocalDate(2025, 10, 1)),
        isFalse,
      );
    });

    test('should_not_equal_a_different_type_when_compared', () {
      expect(LocalDate(2026, 10, 10) == Object(), isFalse);
    });
  });

  group('LocalDate.daysSince', () {
    test('should_count_forward_days_when_this_is_later', () {
      expect(LocalDate(2026, 3, 1).daysSince(LocalDate(2026, 2, 28)), 1);
    });

    test('should_count_backward_days_when_this_is_earlier', () {
      expect(LocalDate(2026, 2, 28).daysSince(LocalDate(2026, 3, 1)), -1);
    });

    test('should_return_zero_when_dates_are_the_same', () {
      final date = LocalDate(2026, 10, 10);

      expect(date.daysSince(date), 0);
    });

    test('should_count_a_full_leap_year_when_spanning_feb_29', () {
      expect(LocalDate(2025, 1, 1).daysSince(LocalDate(2024, 1, 1)), 366);
      expect(LocalDate(2026, 1, 1).daysSince(LocalDate(2025, 1, 1)), 365);
    });

    test('should_count_across_a_year_boundary', () {
      expect(LocalDate(2027, 1, 1).daysSince(LocalDate(2026, 12, 31)), 1);
    });
  });

  group('LocalDate.isoWeekday', () {
    test('should_report_monday_as_one', () {
      // 2026-10-05 is a Monday.
      expect(LocalDate(2026, 10, 5).isoWeekday, DateTime.monday);
    });

    test('should_report_saturday_as_six', () {
      // 2026-10-10 is a Saturday.
      expect(LocalDate(2026, 10, 10).isoWeekday, DateTime.saturday);
    });

    test('should_report_sunday_as_seven', () {
      // 2026-10-11 is a Sunday — the ISO week ends on 7, not 0.
      expect(LocalDate(2026, 10, 11).isoWeekday, DateTime.sunday);
    });
  });

  group('LocalDate.toString', () {
    test('should_format_as_iso_8601', () {
      expect(LocalDate(2026, 10, 10).toString(), '2026-10-10');
    });

    test('should_zero_pad_single_digit_month_and_day', () {
      expect(LocalDate(2026, 1, 5).toString(), '2026-01-05');
    });

    test('should_zero_pad_year_to_four_digits', () {
      expect(LocalDate(999, 1, 1).toString(), '0999-01-01');
    });
  });

  group('InvalidDateError', () {
    test('should_describe_the_offending_date_when_converted_to_string', () {
      final error = InvalidDateError(2026, 2, 30);

      expect(error.toString(), contains('2026-2-30'));
      expect(error.year, 2026);
      expect(error.month, 2);
      expect(error.day, 30);
    });
  });
}
