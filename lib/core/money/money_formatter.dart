import 'package:intl/intl.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';

/// How a [Money] should be rendered.
enum MoneyFormat {
  /// `Ks 1,250` — symbol first (uses a hair space, per docs/Design.md §5.4).
  symbol,

  /// `1,250 Ks` — symbol after the number. Common for MMK in Myanmar.
  symbolSuffix,

  /// `MMK 1,250` — explicit ISO code, used in import/export and ambiguous contexts.
  isoCode,
}

/// Renders [Money] as a localized string.
///
/// **The only component allowed to turn money into text** (docs/Design.md §5.4).
/// Widgets use `AmountText`, which delegates here.
///
/// Grouping comes from `intl` for the active locale; the currency exponent comes
/// from [CurrencyCode], so 0-decimal currencies (MMK, JPY, KRW) never render a
/// spurious `.00`.
///
/// Note on digits: `intl` can transliterate to locale-native digits (e.g. Myanmar
/// digits under `my`). Amounts are rendered with Latin digits app-wide for
/// legibility and column alignment, matching docs/Design.md §3 (tabular figures),
/// so this class builds its own grouping from the locale's separators rather
/// than delegating whole-string rendering to `intl`.
final class MoneyFormatter {
  /// Creates a formatter for [locale].
  ///
  /// [locale] is a BCP-47 tag ('en', 'my', 'ja').
  MoneyFormatter({this.locale = 'en'}) {
    final symbols = NumberFormat.decimalPattern(locale).symbols;
    _groupSeparator = symbols.GROUP_SEP;
    _decimalSeparator = symbols.DECIMAL_SEP;
  }

  /// BCP-47 locale tag used for grouping and separators.
  final String locale;

  late final String _groupSeparator;
  late final String _decimalSeparator;

  /// Formats [money] using this formatter's locale.
  ///
  /// [format] selects symbol placement. [showSign] forces a leading `+`/`−`,
  /// which is what the Calendar summary card needs for income/expense rows
  /// (docs/Design.md §6.3). Uses U+2212 MINUS SIGN, not a hyphen — hyphens are
  /// too short next to tabular figures.
  ///
  /// [useHairSpace] inserts U+2009 between symbol and digits so the two don't
  /// visually merge (docs/Design.md §5.4).
  String format(
    Money money, {
    MoneyFormat format = MoneyFormat.symbol,
    bool showSign = false,
    bool useHairSpace = true,
  }) {
    final digits = _formatMajorUnits(money, useCurrencySeparator: false);
    final sign = switch (money.amountMinor) {
      < 0 => '\u2212', // −
      > 0 when showSign => '+',
      _ => '',
    };

    final symbol = money.currency.symbol;
    final gap = useHairSpace ? '\u2009' : ' ';

    return switch (format) {
      MoneyFormat.symbol => '$sign$symbol$gap$digits',
      MoneyFormat.symbolSuffix => '$sign$digits$gap$symbol',
      MoneyFormat.isoCode => '$sign${money.currency.code}$gap$digits',
    };
  }

  /// Formats just the magnitude, no symbol and no sign.
  ///
  /// Used by the amount keypad display and inline field editing. Uses the
  /// currency's own decimal separator so re-parsing works.
  String formatMagnitude(Money money) =>
      _formatMajorUnits(money, useCurrencySeparator: true);

  /// Formats with an explicit `+`/`−` and no symbol — for compact chart labels.
  String formatSignedMagnitude(Money money) {
    final magnitude = formatMagnitude(money);
    return switch (money.amountMinor) {
      < 0 => '\u2212$magnitude',
      > 0 => '+$magnitude',
      _ => magnitude,
    };
  }

  /// Renders the absolute value of [money] in major units.
  ///
  /// Integer path is used for 0-exponent currencies so no float arithmetic is
  /// involved at all. For 2-exponent currencies the minor part is computed with
  /// integer division so cents are never at the mercy of `double` formatting.
  String _formatMajorUnits(
    Money money, {
    required bool useCurrencySeparator,
  }) {
    final absolute = money.amountMinor.abs();
    final exponent = money.currency.exponent;

    if (exponent == 0) {
      return _groupDigits(absolute.toString());
    }

    var divisor = 1;
    for (var i = 0; i < exponent; i++) {
      divisor *= 10;
    }

    final major = absolute ~/ divisor;
    final minor = absolute % divisor;
    final minorPadded = minor.toString().padLeft(exponent, '0');
    final separator =
        useCurrencySeparator ? money.currency.decimalSeparator : _decimalSeparator;

    return '${_groupDigits(major.toString())}$separator$minorPadded';
  }

  /// Inserts the locale group separator every three digits from the right.
  ///
  /// Implemented directly (rather than via `NumberFormat`) so digits are never
  /// transliterated and the output is deterministic across locales.
  String _groupDigits(String digits) {
    if (digits.length <= 3) return digits;

    final buffer = StringBuffer();
    final firstGroup = digits.length % 3;
    if (firstGroup != 0) {
      buffer.write(digits.substring(0, firstGroup));
      buffer.write(_groupSeparator);
    }
    for (var i = firstGroup; i < digits.length; i += 3) {
      buffer.write(digits.substring(i, i + 3));
      if (i + 3 < digits.length) buffer.write(_groupSeparator);
    }
    return buffer.toString();
  }

  @override
  String toString() => 'MoneyFormatter($locale)';
}
