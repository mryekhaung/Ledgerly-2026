import 'dart:ui' show FontFeature;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/money/money_formatter.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:material_ui/material_ui.dart';

/// Wraps [child] in the minimum context [AmountText] needs: the token layer.
Widget host(
  Widget child, {
  AppColors colors = const AppColorsLight(),
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      home: AppThemeColors(
        colors: colors,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('sign colouring (docs/Design.md §2.4)', () {
    testWidgets('should_use_money_out_and_minus_when_expense', (tester) async {
      await tester.pumpWidget(
        host(const AmountText(Money.minor(-3200, CurrencyCode.mmk))),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.style?.color, const AppColorsLight().moneyOut);
      expect(text.data, startsWith('\u2212'));
    });

    testWidgets('should_use_money_in_and_plus_when_income', (tester) async {
      await tester.pumpWidget(
        host(const AmountText(Money.minor(45000, CurrencyCode.mmk))),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.style?.color, const AppColorsLight().moneyIn);
      expect(text.data, startsWith('+'));
    });

    testWidgets('should_use_primary_text_when_amount_is_zero', (tester) async {
      await tester.pumpWidget(
        host(const AmountText(Money.zero(CurrencyCode.mmk))),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.style?.color, const AppColorsLight().textPrimary);
    });

    testWidgets('should_use_primary_text_when_signed_is_false', (tester) async {
      await tester.pumpWidget(
        host(
          const AmountText(
            Money.minor(-3200, CurrencyCode.mmk),
            signed: false,
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.style?.color, const AppColorsLight().textPrimary);
    });

    testWidgets('should_use_dark_tokens_when_dark_mode', (tester) async {
      await tester.pumpWidget(
        host(
          const AmountText(Money.minor(-3200, CurrencyCode.mmk)),
          colors: const AppColorsDark(),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.style?.color, const AppColorsDark().moneyOut);
    });

    testWidgets('should_honour_explicit_colour_override', (tester) async {
      await tester.pumpWidget(
        host(
          const AmountText(
            Money.minor(-3200, CurrencyCode.mmk),
            color: Color(0xFF123456),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.style?.color, const Color(0xFF123456));
    });
  });

  group('style slots', () {
    testWidgets('should_use_display_style_when_style_is_display',
        (tester) async {
      await tester.pumpWidget(
        host(
          const AmountText(
            Money.minor(1250, CurrencyCode.mmk),
            style: AmountStyle.display,
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.style?.fontSize, 40);
    });

    testWidgets('should_use_large_style_when_style_is_large', (tester) async {
      await tester.pumpWidget(
        host(
          const AmountText(
            Money.minor(1250, CurrencyCode.mmk),
            style: AmountStyle.large,
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.style?.fontSize, 28);
    });

    testWidgets('should_default_to_row_style', (tester) async {
      await tester.pumpWidget(
        host(const AmountText(Money.minor(1250, CurrencyCode.mmk))),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.style?.fontSize, 17);
    });

    testWidgets('should_keep_tabular_figures_in_every_style', (tester) async {
      for (final style in AmountStyle.values) {
        await tester.pumpWidget(
          host(AmountText(Money.minor(1250, CurrencyCode.mmk), style: style)),
        );

        final text = tester.widget<Text>(find.byType(Text).last);
        expect(
          text.style?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
          reason: 'style $style lost tabular figures',
        );
      }
    });
  });

  group('formatting', () {
    testWidgets('should_render_symbol_prefix_by_default', (tester) async {
      await tester.pumpWidget(
        host(const AmountText(Money.minor(1250, CurrencyCode.mmk))),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.data, 'Ks\u20091,250');
    });

    testWidgets('should_render_iso_code_when_format_is_iso_code',
        (tester) async {
      await tester.pumpWidget(
        host(
          const AmountText(
            Money.minor(1250, CurrencyCode.mmk),
            format: MoneyFormat.isoCode,
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.data, contains('MMK'));
    });
  });

  group('accessibility', () {
    testWidgets('should_spell_out_the_sign_when_expense', (tester) async {
      await tester.pumpWidget(
        host(const AmountText(Money.minor(-3200, CurrencyCode.mmk))),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.semanticsLabel, startsWith('minus '));
    });

    testWidgets('should_spell_out_the_sign_when_income', (tester) async {
      await tester.pumpWidget(
        host(const AmountText(Money.minor(45000, CurrencyCode.mmk))),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.semanticsLabel, startsWith('plus '));
    });

    testWidgets('should_have_no_direction_word_when_zero', (tester) async {
      await tester.pumpWidget(
        host(const AmountText(Money.zero(CurrencyCode.mmk))),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.semanticsLabel, isNot(startsWith('minus')));
      expect(text.semanticsLabel, isNot(startsWith('plus')));
    });

    testWidgets('should_prefer_explicit_semantics_label_when_given',
        (tester) async {
      await tester.pumpWidget(
        host(
          const AmountText(
            Money.minor(1250, CurrencyCode.mmk),
            semanticsLabel: 'Custom label',
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.semanticsLabel, 'Custom label');
    });
  });

  group('layout safety', () {
    testWidgets('should_not_overflow_when_text_scaled_to_two', (tester) async {
      await tester.pumpWidget(
        host(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const AmountText(
              Money.minor(1234567, CurrencyCode.mmk),
              style: AmountStyle.display,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should_never_wrap_when_max_lines_defaults', (tester) async {
      await tester.pumpWidget(
        host(const AmountText(Money.minor(1234567, CurrencyCode.mmk))),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });

  group('formatter override', () {
    testWidgets('should_use_injected_formatter_when_provided', (tester) async {
      await tester.pumpWidget(
        host(
          AmountText(
            const Money.minor(1250, CurrencyCode.usd),
            formatter: MoneyFormatter(locale: 'en'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.data, contains('12.50'));
    });
  });
}
