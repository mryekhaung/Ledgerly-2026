import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';

/// Parsing is the one place a user's text becomes a stored amount, so it is the
/// highest-risk surface in the money library.
///
/// The tests below are written against the *integer* contract: the previous
/// implementation routed through `double.tryParse`, which made `1.005 USD`
/// become 100 cents instead of 101. Every case here would have been wrong or
/// unspecified under that implementation.
void main() {
  group('Money.tryParse — exactness', () {
    test('should_round_half_away_from_zero_when_double_would_truncate', () {
      // 1.005 is stored as 1.00499999... as a double, so `* 100 round()` gives
      // 100. The integer parser must give 101.
      expect(Money.tryParse('1.005', CurrencyCode.usd)?.amountMinor, 101);
    });

    test('should_parse_exact_cents_when_input_has_many_decimal_places', () {
      expect(Money.tryParse('0.07', CurrencyCode.usd)?.amountMinor, 7);
      expect(Money.tryParse('10.10', CurrencyCode.usd)?.amountMinor, 1010);
      expect(Money.tryParse('1.10', CurrencyCode.usd)?.amountMinor, 110);
    });

    test('should_reject_amounts_beyond_the_digit_cap_instead_of_losing_cents', () {
      // 900719925474099.99 has 17 significant digits — past the 15-digit cap
      // that guarantees exactness on every platform. It must be rejected rather
      // than silently truncated, which is what a `double` path would do.
      expect(Money.tryParse('900719925474099.99', CurrencyCode.usd), isNull);
    });

    test('should_preserve_cents_at_the_top_of_the_supported_range', () {
      // The largest 15-digit value with cents still parses exactly.
      expect(
        Money.tryParse('9999999999999.99', CurrencyCode.usd)?.amountMinor,
        999999999999999,
      );
    });

    test('should_keep_magnitude_when_value_is_large_in_zero_exponent', () {
      expect(
        Money.tryParse('999999999999999', CurrencyCode.mmk)?.amountMinor,
        999999999999999,
      );
    });
  });

  group('Money.tryParse — rounding at currency precision', () {
    test('should_round_up_at_half_when_currency_has_two_decimals', () {
      expect(Money.tryParse('1.005', CurrencyCode.usd)?.amountMinor, 101);
      expect(Money.tryParse('1.015', CurrencyCode.usd)?.amountMinor, 102);
    });

    test('should_round_down_below_half_when_currency_has_two_decimals', () {
      expect(Money.tryParse('1.004', CurrencyCode.usd)?.amountMinor, 100);
      expect(Money.tryParse('1.0049', CurrencyCode.usd)?.amountMinor, 100);
    });

    test('should_propagate_carry_across_all_digits', () {
      // 99.995 USD -> 9999.5 cents -> 10000 cents. Every digit is a 9, so the
      // carry must add a new leading digit rather than overflow.
      expect(Money.tryParse('99.995', CurrencyCode.usd)?.amountMinor, 10000);
      expect(Money.tryParse('9.999', CurrencyCode.usd)?.amountMinor, 1000);
    });

    test('should_round_when_zero_exponent_currency_receives_decimals', () {
      // MMK/JPY have no minor unit: 1.5 Ks is 2 Ks.
      expect(Money.tryParse('1.5', CurrencyCode.mmk)?.amountMinor, 2);
      expect(Money.tryParse('1.4', CurrencyCode.mmk)?.amountMinor, 1);
      expect(Money.tryParse('1.5', CurrencyCode.jpy)?.amountMinor, 2);
      expect(Money.tryParse('0.4', CurrencyCode.mmk)?.amountMinor, 0);
    });

    test('should_treat_extra_trailing_zeros_as_insignificant', () {
      expect(Money.tryParse('1.500', CurrencyCode.mmk)?.amountMinor, 2);
      expect(Money.tryParse('12.500', CurrencyCode.usd)?.amountMinor, 1250);
      expect(Money.tryParse('1250.00', CurrencyCode.mmk)?.amountMinor, 1250);
    });
  });

  group('Money.tryParse — zero and sign normalisation', () {
    test('should_normalise_negative_zero_to_positive_zero', () {
      // A "-0" that kept its sign would compare equal to 0 but fail an identity
      // check on amountMinor, and would render as "−0" in the UI.
      expect(Money.tryParse('-0', CurrencyCode.usd)?.amountMinor, 0);
      expect(Money.tryParse('-0.00', CurrencyCode.usd)?.amountMinor, 0);
      expect(Money.tryParse('-0.004', CurrencyCode.usd)?.amountMinor, 0);
      expect(Money.tryParse('0', CurrencyCode.usd)?.amountMinor, 0);
      expect(Money.tryParse('+0.000', CurrencyCode.usd)?.amountMinor, 0);
    });

    test('should_apply_sign_when_amount_is_nonzero', () {
      expect(Money.tryParse('-12', CurrencyCode.usd)?.amountMinor, -1200);
      expect(Money.tryParse('+12', CurrencyCode.usd)?.amountMinor, 1200);
      expect(Money.tryParse('-1.005', CurrencyCode.usd)?.amountMinor, -101);
    });

    test('should_accept_unicode_minus_sign', () {
      // U+2212 is what our own formatter emits, so round-tripping must work.
      expect(Money.tryParse('\u221212', CurrencyCode.usd)?.amountMinor, -1200);
    });
  });

  group('Money.tryParse — separators and layout', () {
    test('should_strip_thousands_separators', () {
      expect(Money.tryParse('1,234.56', CurrencyCode.usd)?.amountMinor, 123456);
      expect(
        Money.tryParse('1,234,567', CurrencyCode.mmk)?.amountMinor,
        1234567,
      );
    });

    test('should_strip_non_breaking_and_underscore_spacers', () {
      expect(
        Money.tryParse('12\u00A0000', CurrencyCode.mmk)?.amountMinor,
        12000,
      );
      expect(Money.tryParse('1_000', CurrencyCode.mmk)?.amountMinor, 1000);
    });

    test('should_trim_surrounding_whitespace', () {
      expect(Money.tryParse('  1250  ', CurrencyCode.mmk)?.amountMinor, 1250);
    });

    test('should_accept_missing_integer_or_fraction_part', () {
      expect(Money.tryParse('.5', CurrencyCode.usd)?.amountMinor, 50);
      expect(Money.tryParse('3.', CurrencyCode.mmk)?.amountMinor, 3);
    });

    test('should_normalise_leading_zeros', () {
      expect(Money.tryParse('007', CurrencyCode.mmk)?.amountMinor, 7);
      expect(Money.tryParse('000.50', CurrencyCode.usd)?.amountMinor, 50);
    });

    group('separator ambiguity', () {
      test('should_read_last_separator_as_decimal_when_both_present', () {
        // The universal convention: whichever comes last is the decimal point.
        expect(
          Money.tryParse('1,234.56', CurrencyCode.usd)?.amountMinor,
          123456,
        );
        expect(
          Money.tryParse('1.234,56', CurrencyCode.eur)?.amountMinor,
          123456,
        );
        expect(
          Money.tryParse('1.234.567,89', CurrencyCode.eur)?.amountMinor,
          123456789,
        );
        expect(
          Money.tryParse('1,234,567.89', CurrencyCode.usd)?.amountMinor,
          123456789,
        );
      });

      test('should_treat_own_decimal_marker_as_decimal_not_grouping', () {
        // A single own-separator is never grouping: `1,234` EUR is 1.234 euros.
        // Reading it as 1234 would inflate by 100× on a guess.
        expect(Money.tryParse('12,50', CurrencyCode.eur)?.amountMinor, 1250);
        expect(Money.tryParse('1,234', CurrencyCode.eur)?.amountMinor, 123);
        expect(Money.tryParse('1.005', CurrencyCode.usd)?.amountMinor, 101);
        expect(Money.tryParse('1.234', CurrencyCode.usd)?.amountMinor, 123);
      });

      test('should_treat_foreign_separator_as_decimal_when_not_grouping', () {
        // `1234.56` in EUR: a user typing a dot. Assuming grouping would make
        // it €123,456.00 — a 100× error.
        expect(
          Money.tryParse('1234.56', CurrencyCode.eur)?.amountMinor,
          123456,
        );
        expect(Money.tryParse('12.50', CurrencyCode.eur)?.amountMinor, 1250);
      });

      test('should_treat_foreign_separator_as_grouping_when_3_digits', () {
        // Three trailing digits ⇒ grouping, not a fractional part.
        expect(Money.tryParse('1,234', CurrencyCode.usd)?.amountMinor, 123400);
        expect(Money.tryParse('1,234', CurrencyCode.jpy)?.amountMinor, 1234);
        expect(Money.tryParse('1.234', CurrencyCode.eur)?.amountMinor, 123400);
      });

      test('should_strip_repeated_own_separator_as_valid_grouping', () {
        expect(
          Money.tryParse('1,234,567', CurrencyCode.usd)?.amountMinor,
          123456700,
        );
        expect(
          Money.tryParse('1.234.567', CurrencyCode.eur)?.amountMinor,
          123456700,
        );
      });

      test('should_reject_malformed_group_shapes', () {
        // Repeated separators are only legal as exact 3-digit groups.
        expect(Money.tryParse('1.2.3', CurrencyCode.usd), isNull);
        expect(Money.tryParse('1,2,3', CurrencyCode.eur), isNull);
        expect(Money.tryParse('1.23.456,78', CurrencyCode.eur), isNull);
        expect(Money.tryParse('1,23,456.78', CurrencyCode.usd), isNull);
        expect(Money.tryParse('1.2345,67', CurrencyCode.eur), isNull);
        expect(Money.tryParse('1.2.3,45', CurrencyCode.eur), isNull);
      });
    });
  });

  group('Money.tryParse — rejection', () {
    test('should_return_null_when_input_is_empty_or_blank', () {
      expect(Money.tryParse('', CurrencyCode.usd), isNull);
      expect(Money.tryParse('   ', CurrencyCode.usd), isNull);
      expect(Money.tryParse('\t\n', CurrencyCode.usd), isNull);
    });

    test('should_return_null_when_input_is_only_a_sign', () {
      expect(Money.tryParse('+', CurrencyCode.usd), isNull);
      expect(Money.tryParse('-', CurrencyCode.usd), isNull);
      expect(Money.tryParse('.', CurrencyCode.usd), isNull);
      expect(Money.tryParse('+.', CurrencyCode.usd), isNull);
    });

    test('should_return_null_when_input_has_two_decimal_points', () {
      expect(Money.tryParse('1.2.3', CurrencyCode.usd), isNull);
      expect(Money.tryParse('1,2,3.4.5', CurrencyCode.usd), isNull);
    });

    test('should_return_null_when_input_contains_letters', () {
      expect(Money.tryParse('abc', CurrencyCode.usd), isNull);
      expect(Money.tryParse('12abc', CurrencyCode.usd), isNull);
      expect(Money.tryParse('12e5', CurrencyCode.usd), isNull);
      expect(Money.tryParse('NaN', CurrencyCode.usd), isNull);
      expect(Money.tryParse('Infinity', CurrencyCode.usd), isNull);
    });

    test('should_return_null_when_input_has_repeated_signs', () {
      expect(Money.tryParse('--5', CurrencyCode.usd), isNull);
      expect(Money.tryParse('++5', CurrencyCode.usd), isNull);
      expect(Money.tryParse('-+5', CurrencyCode.usd), isNull);
    });

    test('should_return_null_when_digits_exceed_the_cap', () {
      // 15 digits is the documented maximum; 16 risks exceeding the safe
      // integer range once scaled on every platform.
      expect(Money.tryParse('999999999999999', CurrencyCode.mmk), isNotNull);
      expect(Money.tryParse('9999999999999999', CurrencyCode.mmk), isNull);
      expect(Money.tryParse('99999999999999999', CurrencyCode.mmk), isNull);
    });

    test('should_count_digits_after_removing_leading_zeros', () {
      // Leading zeros are not significant, so a 20-digit string of zeros with
      // a real value inside must still be accepted.
      expect(
        Money.tryParse('000000000000000001', CurrencyCode.mmk)?.amountMinor,
        1,
      );
    });
  });

  group('Money.tryParseAmountMinor', () {
    test('should_return_the_integer_count_when_input_is_valid', () {
      expect(Money.tryParseAmountMinor('12.34', CurrencyCode.usd), 1234);
    });

    test('should_return_null_when_input_is_invalid', () {
      expect(Money.tryParseAmountMinor('abc', CurrencyCode.usd), isNull);
    });
  });

  group('Money.parse — result type', () {
    test('should_report_success_when_input_is_valid', () {
      final result = Money.parse('12.50', CurrencyCode.usd);

      expect(result.isSuccess, isTrue);
      expect(result.money?.amountMinor, 1250);
      expect(result.error, isNull);
    });

    test('should_report_failure_and_keep_input_when_invalid', () {
      final result = Money.parse('abc', CurrencyCode.usd);

      expect(result.isSuccess, isFalse);
      expect(result.money, isNull);
      expect(result.error, MoneyParseError.invalid);
      expect(result.input, 'abc');
      expect(result.currency, CurrencyCode.usd);
    });
  });

  group('Money.negate', () {
    test('should_flip_sign_when_amount_is_positive', () {
      expect(
        const Money.minor(1250, CurrencyCode.mmk).negate().amountMinor,
        -1250,
      );
    });

    test('should_flip_sign_when_amount_is_negative', () {
      expect(
        const Money.minor(-1250, CurrencyCode.mmk).negate().amountMinor,
        1250,
      );
    });

    test('should_be_zero_when_amount_is_zero', () {
      final result = const Money.minor(0, CurrencyCode.mmk).negate();

      expect(result.amountMinor, 0);
      expect(result.isZero, isTrue);
    });

    test('should_preserve_currency_when_negating', () {
      expect(
        const Money.minor(99, CurrencyCode.jpy).negate().currency,
        CurrencyCode.jpy,
      );
    });

    test('should_match_the_unary_minus_operator', () {
      const money = Money.minor(500, CurrencyCode.usd);

      expect(money.negate(), -money);
    });
  });

  group('Money — JPY vs USD exponent behaviour', () {
    test('should_treat_jpy_as_zero_decimal_when_parsing', () {
      // ¥1250 is 1250 yen — there is no 1250.00 breakdown.
      expect(Money.tryParse('1250', CurrencyCode.jpy)?.amountMinor, 1250);
      expect(CurrencyCode.jpy.exponent, 0);
    });

    test('should_treat_usd_as_two_decimal_when_parsing', () {
      expect(Money.tryParse('12.50', CurrencyCode.usd)?.amountMinor, 1250);
      expect(CurrencyCode.usd.exponent, 2);
    });

    test('should_treat_mmk_as_zero_decimal_when_parsing', () {
      expect(Money.tryParse('1250', CurrencyCode.mmk)?.amountMinor, 1250);
      expect(CurrencyCode.mmk.exponent, 0);
    });

    test('should_scale_from_major_by_the_currency_exponent', () {
      expect(Money.fromMajor(1250, CurrencyCode.jpy).amountMinor, 1250);
      expect(Money.fromMajor(12.5, CurrencyCode.usd).amountMinor, 1250);
    });

    test('should_round_half_away_from_zero_in_fromMajor', () {
      expect(Money.fromMajor(1.005, CurrencyCode.usd).amountMinor, 100);
      // Note: at the *fromMajor* boundary the parameter is already a double, so
      // 1.005 has lost its precision before we see it. This documents the
      // known limit and is exactly why tryParse exists.
      expect(Money.tryParse('1.005', CurrencyCode.usd)?.amountMinor, 101);
    });
  });
}
