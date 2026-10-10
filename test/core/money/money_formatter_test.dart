import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/money/money_formatter.dart';

void main() {
  late MoneyFormatter formatter;

  setUp(() {
    formatter = MoneyFormatter(locale: 'en');
  });

  group('format / symbol', () {
    test('should_prefix_symbol_when_format_is_symbol', () {
      final result = formatter.format(
        const Money.minor(1250, CurrencyCode.mmk),
      );

      expect(result, 'Ks\u20091250');
    });

    test('should_group_digits_when_amount_is_large', () {
      final result = formatter.format(
        const Money.minor(1234567, CurrencyCode.mmk),
      );

      expect(result, 'Ks\u20091,234,567');
    });

    test('should_not_render_decimals_when_exponent_is_zero', () {
      final result = formatter.format(const Money.minor(980, CurrencyCode.jpy));

      expect(result, '¥\u2009980');
      expect(result, isNot(contains('.00')));
    });

    test('should_render_minor_units_when_exponent_is_two', () {
      final result = formatter.format(
        const Money.minor(1250, CurrencyCode.usd),
      );

      expect(result, '\$\u200912.50');
    });

    test('should_pad_minor_units_when_below_ten_cents', () {
      expect(
        formatter.format(const Money.minor(5, CurrencyCode.usd)),
        contains('0.05'),
      );
      expect(
        formatter.format(const Money.minor(50, CurrencyCode.usd)),
        contains('0.50'),
      );
    });

    test('should_use_space_when_hair_space_disabled', () {
      final result = formatter.format(
        const Money.minor(1250, CurrencyCode.mmk),
        useHairSpace: false,
      );

      expect(result, 'Ks 1250');
    });
  });

  group('format / sign', () {
    test('should_omit_sign_when_show_sign_is_false_and_negative', () {
      // formatMagnitude-style rendering: sign only when explicitly requested.
      final result = formatter.format(
        const Money.minor(-1250, CurrencyCode.mmk),
        showSign: false,
      );

      expect(result, 'Ks\u20091,250');
    });

    test('should_render_unicode_minus_when_negative_and_show_sign', () {
      final result = formatter.format(
        const Money.minor(-1250, CurrencyCode.mmk),
        showSign: true,
      );

      expect(result, '\u2212Ks\u20091,250');
      expect(result, isNot(startsWith('-')));
    });

    test('should_render_plus_when_positive_and_show_sign', () {
      final result = formatter.format(
        const Money.minor(45000, CurrencyCode.mmk),
        showSign: true,
      );

      expect(result, '+Ks\u200945,000');
    });

    test('should_render_no_sign_when_zero_and_show_sign', () {
      final result = formatter.format(
        const Money.zero(CurrencyCode.mmk),
        showSign: true,
      );

      expect(result, 'Ks\u20090');
    });
  });

  group('format / placement', () {
    test('should_suffix_symbol_when_format_is_symbol_suffix', () {
      final result = formatter.format(
        const Money.minor(1250, CurrencyCode.mmk),
        format: MoneyFormat.symbolSuffix,
      );

      expect(result, '1,250\u2009Ks');
    });

    test('should_use_iso_code_when_format_is_iso_code', () {
      final result = formatter.format(
        const Money.minor(1250, CurrencyCode.mmk),
        format: MoneyFormat.isoCode,
      );

      expect(result, 'MMK\u20091,250');
    });

    test('should_keep_sign_with_iso_code_when_negative', () {
      final result = formatter.format(
        const Money.minor(-1250, CurrencyCode.usd),
        format: MoneyFormat.isoCode,
        showSign: true,
      );

      expect(result, '\u2212USD\u200912.50');
    });
  });

  group('formatMagnitude', () {
    test('should_render_absolute_value_when_amount_is_negative', () {
      expect(
        formatter.formatMagnitude(const Money.minor(-1250, CurrencyCode.mmk)),
        '1,250',
      );
    });

    test('should_group_without_symbol_or_sign', () {
      expect(
        formatter.formatMagnitude(const Money.minor(45000, CurrencyCode.mmk)),
        '45,000',
      );
    });
  });

  group('formatSignedMagnitude', () {
    test('should_prefix_plus_when_positive', () {
      expect(
        formatter.formatSignedMagnitude(
          const Money.minor(45000, CurrencyCode.mmk),
        ),
        '+45,000',
      );
    });

    test('should_prefix_unicode_minus_when_negative', () {
      expect(
        formatter.formatSignedMagnitude(
          const Money.minor(-3200, CurrencyCode.mmk),
        ),
        '\u22123,200',
      );
    });

    test('should_have_no_sign_when_zero', () {
      expect(
        formatter.formatSignedMagnitude(const Money.zero(CurrencyCode.mmk)),
        '0',
      );
    });
  });

  group('round trip', () {
    test('should_survive_parse_format_parse_when_exponent_is_two', () {
      final original = Money.tryParse('1,234.56', CurrencyCode.usd)!;
      const format = MoneyFormat.isoCode;
      final rendered = formatter.format(original, format: format);

      // Strip the ISO code + separator to re-parse.
      final numeric = rendered.split('\u2009').last;
      final reparsed = Money.tryParse(numeric, CurrencyCode.usd);

      expect(reparsed, original);
    });

    test('should_survive_parse_format_parse_when_exponent_is_zero', () {
      final original = Money.tryParse('1,234,567', CurrencyCode.mmk)!;
      final rendered = formatter.formatMagnitude(original);
      final reparsed = Money.tryParse(rendered, CurrencyCode.mmk);

      expect(reparsed, original);
    });
  });
}
