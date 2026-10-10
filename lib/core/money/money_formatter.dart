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

  /// `Ks 1.3k` — magnitude shortened with a Latin suffix (`k`, `M`, `B`).
  ///
  /// For dense contexts only: chart axis labels, capsule summaries, sparkline
  /// callouts. Never for an amount the user is reading or editing.
  compact,

  /// `¥1.3万` — magnitude shortened with Japanese myriad grouping (base 10,000).
  ///
  /// Japanese counts in 万 (10^4), 億 (10^8), 兆 (10^12) rather than thousands,
  /// so `12,500` is `1.25万`, not `12.5k`. Falls back to [compact] when the
  /// magnitude is below 10,000 and therefore has no 万 unit.
  compactMyriad,
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
  /// [format] selects symbol placement.
  ///
  /// [showSign] controls whether a sign is emitted **at all**:
  /// - `true`  → `+` for positive, `−` for negative (`−Ks 1,250`).
  /// - `false` → no sign; the magnitude is rendered unsigned (`Ks 1,250`).
  ///
  /// Amounts are unsigned by default because direction is carried by colour and
  /// layout in the UI (docs/Design.md §2.4) and by the row's label. Callers that
  /// need an explicit sign — the Calendar summary card — pass `showSign: true`.
  ///
  /// Uses U+2212 MINUS SIGN, never a hyphen: hyphens are too short next to
  /// tabular figures.
  ///
  /// [useHairSpace] inserts U+2009 between symbol and digits so the two don't
  /// visually merge (docs/Design.md §5.4).
  String format(
    Money money, {
    MoneyFormat format = MoneyFormat.symbol,
    bool showSign = false,
    bool useHairSpace = true,
    int compactDecimals = 1,
  }) {
    final sign = switch (money.amountMinor) {
      < 0 when showSign => '\u2212', // −
      > 0 when showSign => '+',
      _ => '',
    };

    // Compact modes replace the digit run entirely, so they bypass grouping.
    final String digits;
    final String symbol;
    switch (format) {
      case MoneyFormat.compact:
        digits = formatCompact(money, decimals: compactDecimals);
        symbol = money.currency.symbol;
      case MoneyFormat.compactMyriad:
        digits = formatMyriad(money, decimals: compactDecimals);
        symbol = money.currency.symbol;
      case MoneyFormat.symbol:
      case MoneyFormat.symbolSuffix:
      case MoneyFormat.isoCode:
        digits = _formatMajorUnits(money, useCurrencySeparator: false);
        symbol = money.currency.symbol;
    }

    final gap = useHairSpace ? '\u2009' : ' ';

    return switch (format) {
      MoneyFormat.symbol => '$sign$symbol$gap$digits',
      MoneyFormat.symbolSuffix => '$sign$digits$gap$symbol',
      MoneyFormat.isoCode => '$sign${money.currency.code}$gap$digits',
      // Compact forms read as a measurement: the suffix binds to the digits
      // (`1.3k`), and the currency symbol leads. A hair space would visually
      // split the magnitude from its unit.
      MoneyFormat.compact ||
      MoneyFormat.compactMyriad => '$sign$symbol$gap$digits',
    };
  }

  /// Shortens [money] to a Latin-suffixed magnitude: `1_250` → `1.3k`.
  ///
  /// Uses `k` (10^3), `M` (10^6) and `B` (10^9). The magnitude is in **major**
  /// units, so a 2-exponent currency is scaled by 100 first — `$1,250.00` is
  /// `1.3k`, not `13k` — and the result is never computed through a `double`
  /// for the scaling step.
  ///
  /// A trailing `.0` is dropped so whole magnitudes stay short: `2_000` → `2k`.
  ///
  /// Does **not** include the currency symbol or a sign; [format] composes those.
  String formatCompact(Money money, {int decimals = 1}) {
    assert(decimals >= 0, 'decimals must not be negative');
    final magnitude = money.amountMinor.abs();
    // Work in major units so `k` means "thousand dollars", not "thousand cents".
    final major = _majorUnitsOf(magnitude, money.currency.exponent);
    return _shorten(
      major,
      decimals: decimals,
      decimalSeparator: _decimalSeparator,
    );
  }

  /// Shortens [money] using Japanese myriad units: `12_500` → `1.25万`.
  ///
  /// Japanese groups by 10^4 (万), 10^8 (億), 10^12 (兆). Below 10^4 there is no
  /// unit, so the grouped integer is returned unchanged.
  ///
  /// Does **not** include the currency symbol or a sign; [format] composes those.
  String formatMyriad(Money money, {int decimals = 1}) {
    assert(decimals >= 0, 'decimals must not be negative');
    final magnitude = money.amountMinor.abs();
    final major = _majorUnitsOf(magnitude, money.currency.exponent);

    // Below one 万 there is no unit to attach. Fall back to exact grouping so
    // small amounts are never rendered ambiguously (`0.5万` for 5,000 would
    // round-trip badly and reads worse than `5,000`).
    if (major < 10000) return _groupDigits(major.toString());

    final (divisor, unit) = switch (major) {
      >= 1000000000000 => (1000000000000, '\u5146'), // 兆 10^12
      >= 100000000 => (100000000, '\u5104'), // 億 10^8
      _ => (10000, '\u4E07'), // 万 10^4
    };

    return '${_divideToDecimalString(major, divisor, decimals, _decimalSeparator)}$unit';
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
  String _formatMajorUnits(Money money, {required bool useCurrencySeparator}) {
    final absolute = money.amountMinor.abs();
    final exponent = money.currency.exponent;

    // Grouping separator must be chosen together with the decimal separator.
    // Mixing them (locale grouping + currency decimal) produced `1,234,56` for
    // EUR in an `en` locale — ambiguous and impossible to parse back.
    // With the currency's separators we use its own convention throughout.
    final groupSeparator = useCurrencySeparator
        ? _currencyGroupSeparator(money.currency)
        : _groupSeparator;

    if (exponent == 0) {
      return _groupDigits(absolute.toString(), groupSeparator);
    }

    var divisor = 1;
    for (var i = 0; i < exponent; i++) {
      divisor *= 10;
    }

    final major = absolute ~/ divisor;
    final minor = absolute % divisor;
    final minorPadded = minor.toString().padLeft(exponent, '0');
    final separator = useCurrencySeparator
        ? money.currency.decimalSeparator
        : _decimalSeparator;

    return '${_groupDigits(major.toString(), groupSeparator)}'
        '$separator$minorPadded';
  }

  /// The grouping separator that pairs with [currency]'s decimal separator.
  ///
  /// Uses a thin space when the currency separates decimals with a comma —
  /// following the French/EUR convention (`1 234,56`) — and a comma otherwise.
  /// The two must never collide, or the output cannot be re-parsed.
  static String _currencyGroupSeparator(CurrencyCode currency) =>
      currency.decimalSeparator == ',' ? '\u202F' : ',';

  /// Inserts [separator] every three digits from the right.
  ///
  /// Implemented directly (rather than via `NumberFormat`) so digits are never
  /// transliterated and the output is deterministic across locales.
  String _groupDigits(String digits, [String? separator]) {
    final groupSeparator = separator ?? _groupSeparator;
    if (digits.length <= 3) return digits;

    final buffer = StringBuffer();
    final firstGroup = digits.length % 3;
    if (firstGroup != 0) {
      buffer.write(digits.substring(0, firstGroup));
      buffer.write(groupSeparator);
    }
    for (var i = firstGroup; i < digits.length; i += 3) {
      buffer.write(digits.substring(i, i + 3));
      if (i + 3 < digits.length) buffer.write(groupSeparator);
    }
    return buffer.toString();
  }

  /// Converts a whole minor-unit [amount] to major units as an `int`.
  ///
  /// Integer division — `1250` minor at exponent 2 is `12` major, and the lost
  /// remainder is intentional because compact labels do not render cents.
  static int _majorUnitsOf(int amount, int exponent) {
    if (exponent == 0) return amount;
    var divisor = 1;
    for (var i = 0; i < exponent; i++) {
      divisor *= 10;
    }
    return amount ~/ divisor;
  }

  /// Shortens a major-unit [value] to `k`/`M`/`B` with [decimals] places.
  ///
  /// The division is integer-based: a scaled remainder decides rounding, so no
  /// `double` ever touches the value. A trailing `.0` is trimmed.
  ///
  /// The unit is chosen **after** rounding. Picking it from the raw value would
  /// render `999_999` as `1000k` instead of `1M` — a value that has already
  /// crossed the next threshold must carry the larger suffix.
  static String _shorten(
    int value, {
    required int decimals,
    required String decimalSeparator,
  }) {
    final (divisor, suffix) = _compactUnit(value);
    if (suffix.isEmpty) return value.toString(); // exact — below 1k

    // Try to round up into the next unit (999_999 -> 1M, not 1000k).
    final (nextValue, _) = _roundDiv(value, divisor);
    if (nextValue >= 1000) {
      final (nextDivisor, nextSuffix) = switch (suffix) {
        'k' => (1000000, 'M'),
        'M' => (1000000000, 'B'),
        _ => (divisor, suffix), // B is the largest unit we render
      };
      if (nextSuffix != suffix) {
        return '${_divideToDecimalString(value, nextDivisor, decimals, decimalSeparator)}'
            '$nextSuffix';
      }
    }

    return '${_divideToDecimalString(value, divisor, decimals, decimalSeparator)}$suffix';
  }

  /// Selects the compact unit for [value] by magnitude.
  static (int, String) _compactUnit(int value) => switch (value) {
    >= 1000000000 => (1000000000, 'B'),
    >= 1000000 => (1000000, 'M'),
    >= 1000 => (1000, 'k'),
    _ => (1, ''),
  };

  /// Divides [value] by [divisor] with half-away-from-zero rounding, returning
  /// the rounded quotient and the remainder it was derived from.
  static (int, int) _roundDiv(int value, int divisor) {
    final quotient = value ~/ divisor;
    final remainder = value % divisor;
    return (remainder * 2 >= divisor)
        ? (quotient + 1, remainder)
        : (quotient, remainder);
  }

  /// Divides [value] by [divisor] and renders it with [decimals] places,
  /// rounded half-away-from-zero, using integer arithmetic only.
  ///
  /// `12500 / 10000` with 2 decimals → `1.25`. Trailing zeros are trimmed, and
  /// a zero fraction drops the point entirely (`2000/1000` → `2`).
  ///
  /// Static because it is pure number formatting — it must not depend on the
  /// instance's locale separator, so the separator is passed in explicitly.
  static String _divideToDecimalString(
    int value,
    int divisor,
    int decimals,
    String decimalSeparator,
  ) {
    final scaledDivisor = _pow10Int(decimals);
    // Integer division with an explicit rounding step.
    final numerator = value * scaledDivisor;
    final quotient = numerator ~/ divisor;
    final remainder = numerator % divisor;
    // Round half away from zero, decided on the remainder.
    final rounded = (remainder * 2 >= divisor) ? quotient + 1 : quotient;

    if (decimals == 0) return rounded.toString();

    final raw = rounded.toString().padLeft(decimals + 1, '0');
    final splitAt = raw.length - decimals;
    var whole = raw.substring(0, splitAt);
    var fraction = raw.substring(splitAt);

    // Trim insignificant trailing zeros: `1.50` -> `1.5`, `2.00` -> `2`.
    fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    if (fraction.isEmpty) return whole;
    if (whole.isEmpty) whole = '0';
    return '$whole$decimalSeparator$fraction';
  }

  static int _pow10Int(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  @override
  String toString() => 'MoneyFormatter($locale)';
}
