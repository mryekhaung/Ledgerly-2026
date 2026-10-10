import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/money/money_formatter.dart';

/// Formatting is the last step before a number reaches the user's eye, so these
/// tests pin the exact output per locale and per compact mode.
///
/// Every expectation uses explicit escape sequences (`\u2009` hair space,
/// `\u2212` minus) rather than a literal character, so a copy-paste that
/// silently swaps a hyphen for a minus sign cannot pass.
void main() {
  group('MoneyFormatter — symbol placement', () {
    final formatter = MoneyFormatter(locale: 'en');

    test('should_prefix_symbol_when_format_is_symbol', () {
      expect(
        formatter.format(const Money.minor(1250, CurrencyCode.mmk)),
        'Ks\u20091,250',
      );
    });

    test('should_suffix_symbol_when_format_is_symbolSuffix', () {
      expect(
        formatter.format(
          const Money.minor(1250, CurrencyCode.mmk),
          format: MoneyFormat.symbolSuffix,
        ),
        '1,250\u2009Ks',
      );
    });

    test('should_use_iso_code_when_format_is_isoCode', () {
      expect(
        formatter.format(
          const Money.minor(1250, CurrencyCode.mmk),
          format: MoneyFormat.isoCode,
        ),
        'MMK\u20091,250',
      );
    });

    test('should_use_space_when_hair_space_is_disabled', () {
      expect(
        formatter.format(
          const Money.minor(1250, CurrencyCode.mmk),
          useHairSpace: false,
        ),
        'Ks 1,250',
      );
    });
  });

  group('MoneyFormatter — sign handling', () {
    final formatter = MoneyFormatter(locale: 'en');

    test('should_omit_sign_when_showSign_is_false', () {
      // Direction is carried by colour and layout (docs/Design.md §2.4), so the
      // magnitude is rendered unsigned by default.
      expect(
        formatter.format(const Money.minor(-1250, CurrencyCode.mmk)),
        'Ks\u20091,250',
      );
    });

    test('should_emit_unicode_minus_when_showSign_is_true_and_negative', () {
      expect(
        formatter.format(
          const Money.minor(-1250, CurrencyCode.mmk),
          showSign: true,
        ),
        '\u2212Ks\u20091,250',
      );
    });

    test('should_emit_plus_when_showSign_is_true_and_positive', () {
      expect(
        formatter.format(
          const Money.minor(1250, CurrencyCode.mmk),
          showSign: true,
        ),
        '+Ks\u20091,250',
      );
    });

    test('should_emit_no_sign_when_showSign_is_true_and_zero', () {
      expect(
        formatter.format(
          const Money.minor(0, CurrencyCode.mmk),
          showSign: true,
        ),
        'Ks\u20090',
      );
    });
  });

  group('MoneyFormatter — decimals by currency exponent', () {
    final formatter = MoneyFormatter(locale: 'en');

    test('should_not_render_decimals_when_currency_has_zero_exponent', () {
      expect(
        formatter.format(const Money.minor(1250, CurrencyCode.mmk)),
        'Ks\u20091,250',
      );
      expect(
        formatter.format(const Money.minor(1250, CurrencyCode.jpy)),
        '¥\u20091,250',
      );
    });

    test('should_render_padded_cents_when_currency_has_two_decimals', () {
      expect(
        formatter.format(const Money.minor(1250, CurrencyCode.usd)),
        r'$' + '\u200912.50',
      );
    });

    test('should_render_zero_cents_when_amount_is_whole', () {
      expect(
        formatter.format(const Money.minor(1200, CurrencyCode.usd)),
        r'$' + '\u200912.00',
      );
    });

    test('should_render_single_digit_cents_with_leading_zero', () {
      expect(
        formatter.format(const Money.minor(7, CurrencyCode.usd)),
        r'$' + '\u20090.07',
      );
    });
  });

  group('MoneyFormatter — grouping per locale', () {
    test('should_group_with_commas_when_locale_is_english', () {
      final formatter = MoneyFormatter(locale: 'en');

      expect(
        formatter.format(const Money.minor(1234567, CurrencyCode.mmk)),
        'Ks\u20091,234,567',
      );
    });

    test('should_group_with_commas_when_locale_is_myanmar', () {
      // Myanmar uses the same digit grouping; digits stay Latin for column
      // alignment (docs/Design.md §3).
      final formatter = MoneyFormatter(locale: 'my');

      expect(
        formatter.format(const Money.minor(1234567, CurrencyCode.mmk)),
        'Ks\u20091,234,567',
      );
    });

    test('should_group_with_commas_when_locale_is_japanese', () {
      final formatter = MoneyFormatter(locale: 'ja');

      expect(
        formatter.format(const Money.minor(1234567, CurrencyCode.jpy)),
        '¥\u20091,234,567',
      );
    });

    test('should_return_ungrouped_digits_when_under_one_thousand', () {
      final formatter = MoneyFormatter(locale: 'en');

      expect(
        formatter.format(const Money.minor(999, CurrencyCode.mmk)),
        'Ks\u2009999',
      );
    });
  });

  group('MoneyFormatter — formatMagnitude', () {
    final formatter = MoneyFormatter(locale: 'en');

    test('should_render_absolute_value_without_symbol', () {
      expect(
        formatter.formatMagnitude(const Money.minor(-1250, CurrencyCode.mmk)),
        '1,250',
      );
    });

    test('should_use_currency_separators_when_currency_declares_a_comma', () {
      // EUR separates decimals with ','. The grouping separator must not also be
      // a comma, or the output (`1,234,56`) is ambiguous and cannot be parsed.
      expect(
        formatter.formatMagnitude(const Money.minor(123456, CurrencyCode.eur)),
        '1\u202F234,56',
      );
    });

    test('should_keep_both_separators_consistent_when_currency_uses_a_dot', () {
      // USD uses '.' for decimals, so ',' groups safely.
      expect(
        formatter.formatMagnitude(const Money.minor(123456, CurrencyCode.usd)),
        '1,234.56',
      );
    });

    test('should_group_with_the_currency_separator_for_large_amounts', () {
      expect(
        formatter.formatMagnitude(
          const Money.minor(100000000, CurrencyCode.eur),
        ),
        '1\u202F000\u202F000,00',
      );
    });
  });

  group('MoneyFormatter — formatSignedMagnitude', () {
    final formatter = MoneyFormatter(locale: 'en');

    test('should_prefix_minus_when_negative', () {
      expect(
        formatter.formatSignedMagnitude(
          const Money.minor(-1250, CurrencyCode.mmk),
        ),
        '\u22121,250',
      );
    });

    test('should_prefix_plus_when_positive', () {
      expect(
        formatter.formatSignedMagnitude(
          const Money.minor(1250, CurrencyCode.mmk),
        ),
        '+1,250',
      );
    });

    test('should_emit_bare_zero_when_amount_is_zero', () {
      expect(
        formatter.formatSignedMagnitude(const Money.minor(0, CurrencyCode.mmk)),
        '0',
      );
    });
  });

  group('MoneyFormatter — compact (k/M/B)', () {
    final formatter = MoneyFormatter(locale: 'en');

    test('should_render_exact_value_when_below_one_thousand', () {
      expect(
        formatter.format(
          const Money.minor(999, CurrencyCode.mmk),
          format: MoneyFormat.compact,
        ),
        'Ks\u2009999',
      );
    });

    test('should_use_k_suffix_when_thousands', () {
      expect(
        formatter.format(
          const Money.minor(1250, CurrencyCode.mmk),
          format: MoneyFormat.compact,
        ),
        'Ks\u20091.3k',
      );
    });

    test('should_drop_trailing_zero_when_magnitude_is_whole', () {
      expect(
        formatter.format(
          const Money.minor(2000, CurrencyCode.mmk),
          format: MoneyFormat.compact,
        ),
        'Ks\u20092k',
      );
    });

    test('should_use_M_suffix_when_millions', () {
      expect(
        formatter.format(
          const Money.minor(1500000, CurrencyCode.mmk),
          format: MoneyFormat.compact,
        ),
        'Ks\u20091.5M',
      );
    });

    test('should_use_B_suffix_when_billions', () {
      expect(
        formatter.format(
          const Money.minor(2500000000, CurrencyCode.mmk),
          format: MoneyFormat.compact,
        ),
        'Ks\u20092.5B',
      );
    });

    test('should_promote_to_M_when_rounding_crosses_the_threshold', () {
      // 999,999 rounds to 1000k which is really 1M — the suffix must follow.
      expect(
        formatter.format(
          const Money.minor(999999, CurrencyCode.mmk),
          format: MoneyFormat.compact,
        ),
        'Ks\u20091M',
      );
    });

    test('should_scale_by_exponent_when_currency_has_decimals', () {
      // $1,250.00 is 1.3k dollars, not 13k — the k applies to major units.
      expect(
        formatter.format(
          const Money.minor(125000, CurrencyCode.usd),
          format: MoneyFormat.compact,
        ),
        r'$' + '\u20091.3k',
      );
    });

    test('should_carry_sign_when_showSign_is_true', () {
      expect(
        formatter.format(
          const Money.minor(-1250, CurrencyCode.mmk),
          format: MoneyFormat.compact,
          showSign: true,
        ),
        '\u2212Ks\u20091.3k',
      );
    });

    test('should_honour_compactDecimals_when_set_to_zero', () {
      expect(
        formatter.format(
          const Money.minor(1250, CurrencyCode.mmk),
          format: MoneyFormat.compact,
          compactDecimals: 0,
        ),
        'Ks\u20091k',
      );
    });

    test('should_honour_compactDecimals_when_set_to_two', () {
      expect(
        formatter.format(
          const Money.minor(12345, CurrencyCode.mmk),
          format: MoneyFormat.compact,
          compactDecimals: 2,
        ),
        'Ks\u200912.35k',
      );
    });
  });

  group('MoneyFormatter — Japanese myriad (万/億/兆)', () {
    final formatter = MoneyFormatter(locale: 'ja');

    test('should_render_plain_grouping_when_below_one_myriad', () {
      // 9,999 has no 万 unit; showing "0.9万" would read worse than the number.
      expect(
        formatter.format(
          const Money.minor(9999, CurrencyCode.jpy),
          format: MoneyFormat.compactMyriad,
        ),
        '¥\u20099,999',
      );
    });

    test('should_use_man_when_ten_thousand_or_more', () {
      expect(
        formatter.format(
          const Money.minor(10000, CurrencyCode.jpy),
          format: MoneyFormat.compactMyriad,
        ),
        '¥\u20091\u4E07',
      );
    });

    test('should_render_fraction_of_man_when_between_units', () {
      expect(
        formatter.format(
          const Money.minor(12500, CurrencyCode.jpy),
          format: MoneyFormat.compactMyriad,
        ),
        '¥\u20091.3\u4E07',
      );
    });

    test('should_render_whole_tens_of_man_without_decimals', () {
      expect(
        formatter.format(
          const Money.minor(100000, CurrencyCode.jpy),
          format: MoneyFormat.compactMyriad,
        ),
        '¥\u200910\u4E07',
      );
    });

    test('should_use_oku_when_hundred_million_or_more', () {
      expect(
        formatter.format(
          const Money.minor(100000000, CurrencyCode.jpy),
          format: MoneyFormat.compactMyriad,
        ),
        '¥\u20091\u5104',
      );
    });

    test('should_use_cho_when_trillion_or_more', () {
      expect(
        formatter.format(
          const Money.minor(1234567890123, CurrencyCode.jpy),
          format: MoneyFormat.compactMyriad,
        ),
        '¥\u20091.2\u5146',
      );
    });

    test('should_base_myriad_on_major_units_when_currency_has_decimals', () {
      // 1,250,000 cents = $12,500 = 1.2万 dollars.
      expect(
        formatter.format(
          const Money.minor(1250000, CurrencyCode.usd),
          format: MoneyFormat.compactMyriad,
        ),
        r'$' + '\u20091.3\u4E07',
      );
    });
  });

  group('MoneyFormatter — locale independence of digits', () {
    test('should_keep_latin_digits_when_locale_is_myanmar', () {
      // Amounts stay in Latin digits app-wide so columns align
      // (docs/Design.md §3, tabular figures). Myanmar digits must never appear.
      final formatter = MoneyFormatter(locale: 'my');
      final output = formatter.format(
        const Money.minor(1250, CurrencyCode.mmk),
      );

      expect(output, 'Ks\u20091,250');
      expect(output.runes.every((r) => r < 0x1000 || r > 0x109F), isTrue);
    });

    test('should_keep_latin_digits_when_locale_is_japanese', () {
      final formatter = MoneyFormatter(locale: 'ja');
      // The only non-Latin glyph is the currency symbol itself.
      expect(
        formatter.format(const Money.minor(1250, CurrencyCode.jpy)),
        '¥\u20091,250',
      );
    });
  });

  group('MoneyFormatter — edge cases', () {
    final formatter = MoneyFormatter(locale: 'en');

    test('should_render_zero_when_amount_is_zero', () {
      expect(
        formatter.format(const Money.minor(0, CurrencyCode.usd)),
        r'$' + '\u20090.00',
      );
      expect(
        formatter.format(const Money.minor(0, CurrencyCode.mmk)),
        'Ks\u20090',
      );
    });

    test('should_group_thousands_exactly_at_the_boundary', () {
      expect(
        formatter.format(const Money.minor(1000, CurrencyCode.mmk)),
        'Ks\u20091,000',
      );
      expect(
        formatter.format(const Money.minor(100, CurrencyCode.mmk)),
        'Ks\u2009100',
      );
      expect(
        formatter.format(const Money.minor(10000, CurrencyCode.mmk)),
        'Ks\u200910,000',
      );
    });

    test('should_describe_itself_when_toString_is_called', () {
      expect(formatter.toString(), 'MoneyFormatter(en)');
      expect(MoneyFormatter(locale: 'ja').toString(), 'MoneyFormatter(ja)');
    });
  });
}
