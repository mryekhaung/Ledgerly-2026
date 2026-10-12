import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/amount_entry.dart';
import 'package:ledgerly/core/money/currency_code.dart';

/// Tests for the amount keypad's entry rules.
///
/// These run in pure Dart, with no widget: the rules are where a money bug would
/// hide, so they are tested directly rather than through a tap sequence
/// (`docs/Agent.md` §6).
void main() {
  group('AmountEntry.digit', () {
    test('should_append_digits_to_an_empty_buffer', () {
      expect(AmountEntry.digit('', '1', CurrencyCode.usd), '1');
      expect(AmountEntry.digit('1', '2', CurrencyCode.usd), '12');
    });

    test('should_show_a_lone_zero_when_zero_is_pressed_first', () {
      // The key must visibly do something, even though a leading zero carries
      // no value — otherwise the keypad feels broken.
      expect(AmountEntry.digit('', '0', CurrencyCode.usd), '0');
    });

    test('should_replace_a_lone_leading_zero_rather_than_accumulate_it', () {
      expect(AmountEntry.digit('0', '5', CurrencyCode.usd), '5');
    });

    test('should_keep_a_lone_zero_when_zero_is_pressed_again', () {
      expect(AmountEntry.digit('0', '0', CurrencyCode.usd), '0');
    });

    test('should_keep_appending_after_the_leading_zero_is_replaced', () {
      // `0` then `5` then `0` is 50, not 5.
      expect(AmountEntry.digit('5', '0', CurrencyCode.usd), '50');
    });

    test('should_append_after_a_decimal_point', () {
      expect(AmountEntry.digit('12.', '5', CurrencyCode.usd), '12.5');
    });

    test('should_stop_at_the_maximum_entry_length', () {
      final full = '9' * AmountEntry.maxEntryLength;
      expect(AmountEntry.digit(full, '9', CurrencyCode.usd), full);
    });

    test('should_accept_a_digit_that_still_fits_under_the_cap', () {
      final almost = '9' * (AmountEntry.maxEntryLength - 1);
      expect(
        AmountEntry.digit(almost, '9', CurrencyCode.usd).length,
        AmountEntry.maxEntryLength,
      );
    });
  });

  group('AmountEntry.decimalPoint', () {
    test('should_insert_a_point_into_an_empty_buffer_as_zero_point', () {
      // `.5` is not a number a user means; `0.5` is.
      expect(AmountEntry.decimalPoint('', CurrencyCode.usd), '0.');
    });

    test('should_append_a_point_to_whole_digits', () {
      expect(AmountEntry.decimalPoint('12', CurrencyCode.usd), '12.');
    });

    test('should_ignore_a_second_point', () {
      expect(AmountEntry.decimalPoint('12.5', CurrencyCode.usd), '12.5');
    });

    test('should_be_ignored_entirely_for_a_zero_exponent_currency', () {
      // MMK has no minor unit, so a decimal point is meaningless — not merely
      // rejected at parse time.
      expect(AmountEntry.decimalPoint('12', CurrencyCode.mmk), '12');
      expect(AmountEntry.decimalPoint('', CurrencyCode.mmk), '');
    });

    test('should_be_ignored_at_the_entry_cap', () {
      final full = '9' * AmountEntry.maxEntryLength;
      expect(AmountEntry.decimalPoint(full, CurrencyCode.usd), full);
    });
  });

  group('AmountEntry.backspace', () {
    test('should_remove_the_last_character', () {
      expect(AmountEntry.backspace('12.5'), '12.');
    });

    test('should_no_op_on_an_empty_buffer', () {
      expect(AmountEntry.backspace(''), '');
    });

    test('should_reach_empty_by_repeated_backspace', () {
      var buffer = '123';
      buffer = AmountEntry.backspace(buffer);
      buffer = AmountEntry.backspace(buffer);
      buffer = AmountEntry.backspace(buffer);
      expect(buffer, '');
    });
  });

  group('AmountEntry.hasFullPrecision', () {
    test('should_be_false_without_a_decimal_point', () {
      expect(AmountEntry.hasFullPrecision('12', CurrencyCode.usd), isFalse);
    });

    test('should_be_false_when_a_decimal_is_partially_typed', () {
      expect(AmountEntry.hasFullPrecision('12.5', CurrencyCode.usd), isFalse);
    });

    test('should_be_true_once_the_full_precision_is_typed', () {
      expect(AmountEntry.hasFullPrecision('12.50', CurrencyCode.usd), isTrue);
    });

    test(
      'should_be_true_immediately_after_the_point_for_a_zero_exponent_currency',
      () {
        // A zero-exponent currency can never carry a point, so `12.` is already
        // over-precise rather than merely incomplete.
        expect(AmountEntry.hasFullPrecision('12.', CurrencyCode.mmk), isTrue);
      },
    );
  });

  group('AmountEntry.clear', () {
    test('should_return_an_empty_buffer', () {
      expect(AmountEntry.clear(), '');
    });
  });
}
