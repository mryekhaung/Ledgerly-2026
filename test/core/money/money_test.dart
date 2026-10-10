import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';

/// Money is the correctness core of a finance app, so these tests are exhaustive
/// about rounding, currency safety, and the double-vs-int boundary.
void main() {
  group('Money.minor', () {
    test('should_hold_exact_minor_units_when_constructed_from_minor', () {
      const money = Money.minor(1250, CurrencyCode.mmk);

      expect(money.amountMinor, 1250);
      expect(money.currency, CurrencyCode.mmk);
    });

    test('should_report_helpers_when_amount_is_signed', () {
      expect(const Money.minor(5, CurrencyCode.mmk).isPositive, isTrue);
      expect(const Money.minor(-5, CurrencyCode.mmk).isNegative, isTrue);
      expect(const Money.minor(0, CurrencyCode.mmk).isZero, isTrue);
      expect(const Money.minor(0, CurrencyCode.mmk).isPositive, isFalse);
      expect(const Money.minor(0, CurrencyCode.mmk).isNegative, isFalse);
    });
  });

  group('Money.fromMajor', () {
    test('should_scale_by_currency_exponent_when_exponent_is_two', () {
      expect(
        Money.fromMajor(12.5, CurrencyCode.usd).amountMinor,
        1250,
      );
    });

    test('should_not_scale_when_exponent_is_zero', () {
      expect(Money.fromMajor(1250, CurrencyCode.mmk).amountMinor, 1250);
      expect(Money.fromMajor(980, CurrencyCode.jpy).amountMinor, 980);
    });

    test('should_round_half_away_from_zero_when_too_many_decimals', () {
      // 10.005 USD -> 1000.5 cents -> 1001
      expect(Money.fromMajor(10.005, CurrencyCode.usd).amountMinor, 1001);
      // 10.004 USD -> 1000.4 cents -> 1000
      expect(Money.fromMajor(10.004, CurrencyCode.usd).amountMinor, 1000);
      // negative rounds away from zero too
      expect(Money.fromMajor(-10.005, CurrencyCode.usd).amountMinor, -1001);
    });

    test('should_be_exact_when_double_representation_would_drift', () {
      // 0.1 + 0.2 == 0.30000000000000004 as doubles; minor units must stay exact.
      final sum = Money.fromMajor(0.1, CurrencyCode.usd) +
          Money.fromMajor(0.2, CurrencyCode.usd);

      expect(sum.amountMinor, 30);
      expect(sum.toMajor(), 0.3);
    });
  });

  group('Money.tryParse', () {
    test('should_parse_plain_decimal_when_valid', () {
      expect(Money.tryParse('1250', CurrencyCode.mmk)?.amountMinor, 1250);
      expect(Money.tryParse('12.50', CurrencyCode.usd)?.amountMinor, 1250);
    });

    test('should_strip_grouping_separators_when_present', () {
      expect(Money.tryParse('1,234.56', CurrencyCode.usd)?.amountMinor, 123456);
      expect(Money.tryParse('1,234,567', CurrencyCode.mmk)?.amountMinor, 1234567);
    });

    test('should_accept_leading_sign_when_provided', () {
      expect(Money.tryParse('-12', CurrencyCode.usd)?.amountMinor, -1200);
      expect(Money.tryParse('+12', CurrencyCode.usd)?.amountMinor, 1200);
    });

    test('should_return_null_when_input_is_not_numeric', () {
      expect(Money.tryParse('', CurrencyCode.usd), isNull);
      expect(Money.tryParse('  ', CurrencyCode.usd), isNull);
      expect(Money.tryParse('abc', CurrencyCode.usd), isNull);
      expect(Money.tryParse('12abc', CurrencyCode.usd), isNull);
      expect(Money.tryParse('NaN', CurrencyCode.usd), isNull);
      expect(Money.tryParse('Infinity', CurrencyCode.usd), isNull);
    });
  });

  group('arithmetic', () {
    test('should_add_when_currencies_match', () {
      final result = const Money.minor(1000, CurrencyCode.mmk) +
          const Money.minor(250, CurrencyCode.mmk);

      expect(result.amountMinor, 1250);
    });

    test('should_subtract_when_currencies_match', () {
      final result = const Money.minor(1000, CurrencyCode.mmk) -
          const Money.minor(250, CurrencyCode.mmk);

      expect(result.amountMinor, 750);
    });

    test('should_negate_when_unary_minus_applied', () {
      expect((-const Money.minor(500, CurrencyCode.mmk)).amountMinor, -500);
      expect((-const Money.minor(-500, CurrencyCode.mmk)).amountMinor, 500);
    });

    test('should_scale_by_integer_factor_when_multiplied', () {
      expect(
        (const Money.minor(250, CurrencyCode.mmk) * 4).amountMinor,
        1000,
      );
    });

    test('should_return_magnitude_when_abs_called', () {
      expect(const Money.minor(-700, CurrencyCode.mmk).abs().amountMinor, 700);
      expect(const Money.minor(700, CurrencyCode.mmk).abs().amountMinor, 700);
    });

    test('should_throw_currency_mismatch_when_adding_different_currencies', () {
      expect(
        () => const Money.minor(100, CurrencyCode.mmk) +
            const Money.minor(100, CurrencyCode.usd),
        throwsA(isA<CurrencyMismatchError>()),
      );
    });

    test('should_throw_currency_mismatch_when_comparing_different_currencies', () {
      expect(
        () => const Money.minor(100, CurrencyCode.mmk)
            .compareTo(const Money.minor(100, CurrencyCode.usd)),
        throwsA(isA<CurrencyMismatchError>()),
      );
    });

    test('should_keep_currency_when_arithmetic_applied', () {
      final result = const Money.minor(100, CurrencyCode.jpy) +
          const Money.minor(100, CurrencyCode.jpy);

      expect(result.currency, CurrencyCode.jpy);
    });
  });

  group('comparison', () {
    test('should_order_by_amount_when_currencies_match', () {
      const small = Money.minor(100, CurrencyCode.mmk);
      const large = Money.minor(200, CurrencyCode.mmk);

      expect(small < large, isTrue);
      expect(small <= large, isTrue);
      expect(large > small, isTrue);
      expect(large >= small, isTrue);
      expect(small.compareTo(large), lessThan(0));
      expect(large.compareTo(small), greaterThan(0));
      expect(small.compareTo(small), 0);
    });

    test('should_treat_amounts_of_equal_value_as_equal', () {
      expect(
        const Money.minor(500, CurrencyCode.mmk),
        const Money.minor(500, CurrencyCode.mmk),
      );
      expect(
        const Money.minor(500, CurrencyCode.mmk),
        isNot(const Money.minor(500, CurrencyCode.usd)),
      );
      expect(
        const Money.minor(500, CurrencyCode.mmk),
        isNot(const Money.minor(501, CurrencyCode.mmk)),
      );
    });

    test('should_hash_equally_when_values_are_equal', () {
      expect(
        const Money.minor(500, CurrencyCode.mmk).hashCode,
        const Money.minor(500, CurrencyCode.mmk).hashCode,
      );
    });
  });

  group('toMajor', () {
    test('should_divide_by_exponent_when_converting', () {
      expect(const Money.minor(1250, CurrencyCode.usd).toMajor(), 12.5);
      expect(const Money.minor(1250, CurrencyCode.mmk).toMajor(), 1250);
    });
  });

  group('toString', () {
    test('should_show_no_decimal_point_when_exponent_is_zero', () {
      expect(
        const Money.minor(1250, CurrencyCode.mmk).toString(),
        '1250 MMK',
      );
    });

    test('should_pad_minor_units_when_exponent_is_two', () {
      expect(const Money.minor(1250, CurrencyCode.usd).toString(), '12.50 USD');
      expect(const Money.minor(5, CurrencyCode.usd).toString(), '0.05 USD');
      expect(const Money.minor(100, CurrencyCode.usd).toString(), '1.00 USD');
    });

    test('should_render_sign_before_major_units_when_negative', () {
      expect(const Money.minor(-1250, CurrencyCode.usd).toString(), '-12.50 USD');
    });
  });

  group('CurrencyCode', () {
    test('should_parse_case_insensitively_when_code_is_known', () {
      expect(CurrencyCode.tryParse('mmk'), CurrencyCode.mmk);
      expect(CurrencyCode.tryParse('MmK'), CurrencyCode.mmk);
      expect(CurrencyCode.tryParse('  USD  '), CurrencyCode.usd);
    });

    test('should_return_null_when_code_is_unknown', () {
      expect(CurrencyCode.tryParse('XYZ'), isNull);
      expect(CurrencyCode.tryParse(''), isNull);
    });

    test('should_expose_zero_exponent_for_mmk_jpy_krw', () {
      expect(CurrencyCode.mmk.exponent, 0);
      expect(CurrencyCode.jpy.exponent, 0);
      expect(CurrencyCode.krw.exponent, 0);
    });

    test('should_expose_two_exponent_for_decimal_currencies', () {
      expect(CurrencyCode.usd.exponent, 2);
      expect(CurrencyCode.eur.exponent, 2);
      expect(CurrencyCode.sgd.exponent, 2);
    });
  });
}
