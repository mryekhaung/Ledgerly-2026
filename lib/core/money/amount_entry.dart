import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';

/// The digit-entry rules for the amount keypad.
///
/// Pure Dart and separate from the widget so every rule below is unit-testable
/// and the widget is left with nothing but rendering and hit testing
/// (`docs/Agent.md` §6). The rules mirror a physical calculator:
///
/// * a currency with `exponent 0` (MMK, JPY, KRW) never accepts a decimal point
///   at all, because there is no minor unit to enter;
/// * a second decimal point is ignored rather than accepted and silently
///   truncated;
/// * decimals stop at the currency's precision, so `USD` will not take a third
///   digit after the point;
/// * a leading zero is replaced rather than accumulated, so `0` then `5` reads
///   `5` and not `05`.
abstract final class AmountEntry {
  const AmountEntry._();

  /// The longest entry the keypad will hold, in characters.
  ///
  /// Longer than `Money.maxDigits` on purpose: the parse is what rejects an
  /// overflowing amount, and clipping the buffer at the exact digit limit would
  /// stop the user from ever seeing *why* their entry is refused.
  static const int maxEntryLength = Money.maxDigits + 2;

  /// Appends [digit] (a single `0`–`9`) to [buffer].
  ///
  /// Returns the new buffer, or [buffer] unchanged when the key is ignored.
  static String digit(String buffer, String digit, CurrencyCode currency) {
    assert(
      digit.length == 1 && int.tryParse(digit) != null,
      'digit() expects a single 0-9 character',
    );

    if (buffer.length >= maxEntryLength) return buffer;

    // A lone leading zero is a placeholder, not a significant digit: typing `5`
    // after it means 5, not 05.
    if (buffer == '0') return digit == '0' ? buffer : digit;

    // Nothing typed yet and the user presses 0 — show `0` so the key visibly
    // does something, then let the rule above take over on the next digit.
    if (buffer.isEmpty && digit == '0') return '0';

    return buffer + digit;
  }

  /// Appends a decimal point to [buffer], or returns it unchanged.
  ///
  /// Ignored entirely for a zero-exponent currency, and ignored when a point is
  /// already present.
  static String decimalPoint(String buffer, CurrencyCode currency) {
    if (currency.exponent == 0) return buffer;
    if (buffer.contains('.')) return buffer;
    if (buffer.length >= maxEntryLength) return buffer;
    // `5.` is a valid intermediate state — the fraction is simply empty.
    return buffer.isEmpty ? '0.' : '$buffer.';
  }

  /// Removes the last character of [buffer].
  static String backspace(String buffer) =>
      buffer.isEmpty ? buffer : buffer.substring(0, buffer.length - 1);

  /// Clears the entry.
  static String clear() => '';

  /// True when [buffer] already carries the currency's full decimal precision,
  /// so a further digit key would be ignored.
  ///
  /// The widget uses this to decide whether to render a digit key as muted.
  static bool hasFullPrecision(String buffer, CurrencyCode currency) {
    final pointIndex = buffer.indexOf('.');
    if (pointIndex == -1) return false;
    return buffer.length - pointIndex - 1 >= currency.exponent;
  }
}
