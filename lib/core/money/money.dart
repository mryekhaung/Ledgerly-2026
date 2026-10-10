import 'package:ledgerly/core/money/currency_code.dart';

/// An exact monetary amount: a whole number of **minor units** plus a currency.
///
/// **Never use `double` for money** (docs/Agent.md §3.5, docs/Architecture.md ADR #2).
/// `1_250` is 1,250 Ks; `1250` USD is $12.50. The unit is unambiguous because it
/// always travels with [currency].
///
/// Immutable value type — every operation returns a new [Money].
final class Money implements Comparable<Money> {
  /// Creates an amount from whole minor units (cents, pyas, yen).
  ///
  /// This is the canonical constructor; prefer it over [Money.fromMajor].
  const Money.minor(this.amountMinor, this.currency);

  /// Zero in [currency].
  const Money.zero(this.currency) : amountMinor = 0;

  /// Creates an amount from a major-unit value, e.g. `Money.fromMajor(12.5, usd)`
  /// → 1250 cents. Rounds half-away-from-zero, which is the accounting default.
  ///
  /// **Boundary use only** — parsing user input or CSV. Internally the app always
  /// works in minor units. For text input prefer [Money.parse], which is
  /// exact; this constructor must go through a `double` because its parameter is
  /// one, so very large magnitudes can lose precision.
  factory Money.fromMajor(num major, CurrencyCode currency) {
    final scaled = major * _pow10(currency.exponent);
    // `round()` on a double is half-away-from-zero in Dart.
    return Money.minor(scaled.round(), currency);
  }

  /// The largest number of **total digits** an input may contain.
  ///
  /// 15 keeps every intermediate product inside the safe-integer range
  /// (±2^53 ≈ 9.007e15) that Dart guarantees on **all** platforms including web,
  /// where `int` is a 32-bit-ish JS number. Rejecting beyond this is a
  /// correctness guarantee, not an arbitrary cap.
  static const int maxDigits = 15;

  /// Parses [input] into [currency], or returns null when it is not a valid
  /// amount.
  ///
  /// Accepts an optional leading `+`/`-`, thousands separators (`,` and U+00A0),
  /// and at most one decimal point: `1,234.56`, `1234`, `-12`, `.5`, `5.`.
  ///
  /// **Pure integer arithmetic — no `double` anywhere.** A naive
  /// `double.tryParse(...) * 100` is wrong: `1.005` is stored as
  /// `1.00499999...` so it rounds to `100` cents instead of `101`. This parser
  /// splits on the decimal point and assembles the digit string, so the result
  /// is exact.
  ///
  /// Rejects:
  /// - empty or whitespace-only input
  /// - input with more than [maxDigits] digits (overflow guard)
  /// - more decimal places than [CurrencyCode.exponent] allows
  /// - a bare sign, a bare separator, or any non-numeric character
  /// - a value that would overflow the platform integer
  ///
  /// Returns null rather than throwing so callers can map to a
  /// `ValidationFailure` (docs/Architecture.md §8).
  static Money? tryParse(String input, CurrencyCode currency) {
    final minor = tryParseAmountMinor(input, currency);
    if (minor == null) return null;
    return Money.minor(minor, currency);
  }

  /// Parses [input] into whole minor units, or returns null when invalid.
  ///
  /// The integer-returning core of [tryParse] — useful when the caller wants the
  /// raw count (e.g. keypad state) before wrapping it in a [Money].
  ///
  /// Never produces `-0`: a parsed zero is always `0` with no sign, so
  /// `Money.zero(c).amountMinor == 0` holds for `'-0'`, `'-0.00'` and `'0'`.
  static int? tryParseAmountMinor(String input, CurrencyCode currency) {
    // Whitespace-style grouping is unambiguous, so it is stripped first.
    final stripped = input
        .trim()
        .replaceAll('\u00A0', '') // non-breaking space
        .replaceAll('\u202F', '') // narrow no-break space (EUR grouping)
        .replaceAll('\u2009', '') // thin space
        .replaceAll(' ', '') // plain space grouping
        .replaceAll('_', '');

    if (stripped.isEmpty) return null;

    final cleaned = _normaliseSeparators(stripped, currency);
    if (cleaned == null) return null;

    var body = cleaned;
    var negative = false;
    if (body.startsWith('+')) {
      body = body.substring(1);
    } else if (body.startsWith('-') || body.startsWith('\u2212')) {
      negative = true;
      body = body.substring(1);
    }

    if (body.isEmpty) return null;

    final dotIndex = body.indexOf('.');
    final String integerPart;
    final String fractionPart;
    if (dotIndex == -1) {
      integerPart = body;
      fractionPart = '';
    } else {
      // Reject a second decimal point (e.g. `1.2.3`).
      if (body.indexOf('.', dotIndex + 1) != -1) return null;
      integerPart = body.substring(0, dotIndex);
      fractionPart = body.substring(dotIndex + 1);
    }

    // A lone `.` carries no digits at all.
    if (integerPart.isEmpty && fractionPart.isEmpty) return null;

    // Every remaining character must be an ASCII digit.
    if (!_isAllDigits(integerPart) || !_isAllDigits(fractionPart)) return null;

    // Extra decimal places are rounded half-away-from-zero at the currency's
    // precision — the accounting default. `1.005 USD` becomes 101 cents rather
    // than 100 (the value a `double` would silently produce) or an outright
    // rejection: a user typing sub-cent precision wants an amount, not an error.
    final rounded = _roundToExponent(
      integerPart,
      fractionPart,
      currency.exponent,
    );

    final digits = rounded;
    // Leading zeros are insignificant: `007` is 7.
    final significant = digits.replaceFirst(RegExp(r'^0+'), '');
    final digitCount = significant.isEmpty ? 1 : significant.length;
    if (digitCount > maxDigits) return null;

    final magnitude = int.tryParse(digits.isEmpty ? '0' : digits);
    if (magnitude == null) return null;

    // Normalise negative zero so `-0` and `0` are the same value.
    if (magnitude == 0) return 0;
    return negative ? -magnitude : magnitude;
  }

  /// Parses [input] into [currency], returning a result instead of null.
  ///
  /// The domain-facing entry point: callers get a reason on failure rather
  /// than a bare null.
  static MoneyParseResult parse(String input, CurrencyCode currency) {
    final minor = tryParseAmountMinor(input, currency);
    if (minor == null) {
      return MoneyParseResult.failure(
        MoneyParseError.invalid,
        input: input,
        currency: currency,
      );
    }
    return MoneyParseResult.success(Money.minor(minor, currency));
  }

  /// Normalises `.` and `,` into a single `.` decimal point, using [currency]'s
  /// convention to resolve ambiguity.
  ///
  /// The rules, in order:
  /// - Both separators present (`1.234,56` / `1,234.56`): the **last** one is the
  ///   decimal point and the other is grouping — the universal convention.
  /// - One separator present, matching the currency's own decimal marker
  ///   (`12,50` / `1.005` in EUR / USD): the decimal point. Read `1,234` EUR as
  ///   1.234 euros, not 1234 — never inflate on a guess.
  /// - The own marker repeated (`1,234,567` USD): grouping, if the groups are
  ///   well-formed; otherwise reject (`1.2.3`).
  /// - Only the *other* separator present with exactly 3 digits after it
  ///   (`1,234` in USD): grouping.
  /// - Only the other separator present with 1–2 digits after it (`1234.56` in
  ///   EUR — a user typing a dot): treat it as the decimal point. Assuming
  ///   grouping here would turn €1,234.56 into €123,456.00, a 100× error.
  ///
  /// Returns null when a single decimal point would be ambiguous — e.g. the
  /// both-present form where the decimal character repeats (`1,234,56` in EUR).
  static String? _normaliseSeparators(String input, CurrencyCode currency) {
    final decimalSeparator = currency.decimalSeparator;

    final lastComma = input.lastIndexOf(',');
    final lastDot = input.lastIndexOf('.');

    final hasComma = lastComma != -1;
    final hasDot = lastDot != -1;

    if (!hasComma && !hasDot) return input; // plain integer

    if (hasComma && hasDot) {
      // Whichever appears last is the decimal point; drop the other entirely.
      final decimalIsComma = lastComma > lastDot;
      final decimal = decimalIsComma ? ',' : '.';
      final grouping = decimalIsComma ? '.' : ',';
      // A grouping character may legitimately repeat; the decimal one may not.
      final withoutGrouping = input.replaceAll(grouping, '');
      if (withoutGrouping.split(decimal).length > 2) return null;
      // Validate the grouping structure on the integer portion *as written*
      // (separators intact) — `1.234.567` is well-formed, `1.2.34` is not.
      final integerSide = input.split(decimal).first;
      if (integerSide.isNotEmpty && !_isValidGrouping(integerSide, grouping)) {
        return null;
      }
      return withoutGrouping.replaceAll(decimal, '.');
    }

    // Exactly one separator kind is present.
    final present = hasComma ? ',' : '.';
    final index = hasComma ? lastComma : lastDot;
    final digitsAfter = input.length - index - 1;
    final occurrences = RegExp(RegExp.escape(present)).allMatches(input).length;

    if (present == decimalSeparator) {
      // The currency's own decimal marker. A single occurrence is *always* the
      // decimal point: `1.005` USD is 1.005 dollars (→ 101 cents after the
      // currency-precision round), and `1,234` EUR is 1.234 euros (→ 123 cents).
      // Reading the latter as grouping would be guessing; the decimal reading is
      // what every form-input parser does, and it fails safe (never inflates).
      if (occurrences == 1) return input.replaceAll(present, '.');
      // Repeating can only be grouping (`1,234,567` USD): the decimal marker is
      // never written twice in a well-formed amount. Accept it when the groups
      // really are 3 digits, reject `1.2.3` otherwise.
      return _isValidGrouping(input, present)
          ? input.replaceAll(present, '')
          : null;
    }

    // The *other* separator (e.g. `.` typed by a user in a comma-decimal
    // currency). NB: the other separator *is* this currency's grouping character,
    // so the conversion must happen in one step — stripping the grouping first
    // would delete the very separator we mean to keep as the decimal point.
    if (occurrences == 1) {
      // Exactly 3 digits trailing and not at the head ⇒ grouping (`1,234` USD).
      return digitsAfter == 3 && index != 0
          ? input.replaceAll(present, '')
          : input.replaceAll(present, '.');
    }
    // Repeating: grouping only when the groups really are 3 digits.
    return _isValidGrouping(input, present)
        ? input.replaceAll(present, '')
        : null;
  }

  /// Whether [separator] in [input] is used as valid 3-digit grouping.
  ///
  /// A value with no separator at all (`1234`) is fine. Where separators do
  /// appear, the leading group may be 1–3 digits and every following group must
  /// be exactly 3: accepts `1,234,567` and `12,345`, rejects `1,2,3` and
  /// `1,23,456`.
  static bool _isValidGrouping(String input, String separator) {
    final groups = input.split(separator);
    if (groups.length == 1) return true; // unseparated integer
    for (var i = 1; i < groups.length; i++) {
      if (groups[i].length != 3) return false;
    }
    final head = groups.first;
    return head.isEmpty ? groups.length == 2 : head.length <= 3;
  }

  /// The amount in minor units. Always whole — this is the source of truth.
  final int amountMinor;

  /// The currency this amount is denominated in.
  final CurrencyCode currency;

  /// True when the amount is exactly zero.
  bool get isZero => amountMinor == 0;

  /// True when the amount is greater than zero.
  bool get isPositive => amountMinor > 0;

  /// True when the amount is less than zero.
  bool get isNegative => amountMinor < 0;

  /// The major-unit value as a double.
  ///
  /// **Display and boundary use only.** Never do arithmetic with this — it
  /// reintroduces floating-point error, which is the bug this class exists to prevent.
  double toMajor() => amountMinor / _pow10(currency.exponent);

  /// This amount negated (expense ⇄ income direction).
  ///
  /// Named form of the unary minus operator, for use as a tear-off
  /// (`list.map((m) => m.negate())`) and in const-adjacent contexts.
  Money negate() => Money.minor(-amountMinor, currency);

  /// Creates an amount in [to] carrying the same minor-unit count.
  ///
  /// This does **not** convert value — no FX rate is applied (see Roadmap backlog
  /// "multi-currency FX"). Only use it when you have already converted the amount.
  Money withCurrency(CurrencyCode to) => Money.minor(amountMinor, to);

  /// Adds [other], which must share this currency.
  ///
  /// Throws [CurrencyMismatchError] on mismatch: silently adding MMK to USD is
  /// always a bug, and failing loudly at the boundary is safer than a wrong total.
  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money.minor(amountMinor + other.amountMinor, currency);
  }

  /// Subtracts [other], which must share this currency.
  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money.minor(amountMinor - other.amountMinor, currency);
  }

  /// Negates the amount (expense ⇄ income direction).
  Money operator -() => Money.minor(-amountMinor, currency);

  /// Scales by an integer factor (e.g. a quantity).
  Money operator *(int factor) => Money.minor(amountMinor * factor, currency);

  /// The absolute value, keeping the sign-positive magnitude.
  Money abs() => Money.minor(amountMinor.abs(), currency);

  /// Compares by value. Throws [CurrencyMismatchError] on a currency mismatch —
  /// comparing across currencies is meaningless without an FX rate.
  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return amountMinor.compareTo(other.amountMinor);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  /// Value equality across amount **and** currency (`5 Ks != 5 USD`).
  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amountMinor == amountMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amountMinor, currency);

  /// Debug representation with a resolved decimal point. Not for UI — use
  /// `MoneyFormatter` for anything the user sees.
  @override
  String toString() {
    if (currency.exponent == 0) {
      return '$amountMinor ${currency.code}';
    }
    final sign = amountMinor < 0 ? '-' : '';
    final absolute = amountMinor.abs();
    final divisor = _pow10(currency.exponent);
    final major = absolute ~/ divisor;
    final minor = absolute % divisor;
    final padded = minor.toString().padLeft(currency.exponent, '0');
    return '$sign$major.$padded ${currency.code}';
  }

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw CurrencyMismatchError(currency, other.currency);
    }
  }

  static bool _isAllDigits(String value) {
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code < 0x30 || code > 0x39) return false;
    }
    return true;
  }

  /// Builds the concatenated minor-unit digit string, rounding away from zero.
  ///
  /// [integerPart] and [fractionPart] are already validated as ASCII digits
  /// (either may be empty). The result is the digits of the **magnitude** in
  /// minor units — sign is applied by the caller.
  ///
  /// Rounding is done on the digit string, not on a number, so it is exact for
  /// any input length. A digit `>= 5` in the first discarded position carries
  /// into the kept digits; `1.005` (USD) and `1.5` (MMK) both round up to the
  /// next minor unit.
  static String _roundToExponent(
    String integerPart,
    String fractionPart,
    int exponent,
  ) {
    final keptFraction = fractionPart.length <= exponent
        ? fractionPart.padRight(exponent, '0')
        : fractionPart.substring(0, exponent);

    // Everything past `exponent` decides the rounding direction.
    final discarded = fractionPart.length <= exponent
        ? ''
        : fractionPart.substring(exponent);

    var digits = '$integerPart$keptFraction';
    if (digits.isEmpty) digits = '0';

    if (!_shouldRoundUp(discarded)) return digits;

    // Add 1 to the last position, propagating the carry leftwards.
    final chars = digits.codeUnits.toList(growable: true);
    var i = chars.length - 1;
    while (i >= 0) {
      if (chars[i] == 0x39) {
        chars[i] = 0x30;
        i--;
      } else {
        chars[i] = chars[i] + 1;
        return String.fromCharCodes(chars);
      }
    }
    // Every digit was a 9 — the carry adds a new leading 1 (`99.999` -> `10000`).
    return '1${String.fromCharCodes(chars)}';
  }

  /// True when [discarded] (the digits past the currency precision) warrants
  /// rounding the magnitude up: the first dropped digit is 5 or more.
  ///
  /// Half-away-from-zero: `…5` rounds up regardless of what follows, which is
  /// the accounting convention and avoids a float-style "banker's" surprise.
  static bool _shouldRoundUp(String discarded) {
    if (discarded.isEmpty) return false;
    return discarded.codeUnitAt(0) >= 0x35; // '5'
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}

/// Why [Money.parse] rejected an input.
enum MoneyParseError {
  /// Empty input, a bare sign, a stray character, or too much precision.
  invalid,

  /// More than [Money.maxDigits] significant digits — would risk overflow.
  tooManyDigits,
}

/// Outcome of [Money.parse].
///
/// Deliberately not a `Result<Money>`: `core/money` is a leaf value-type library
/// and must not depend on `core/result`, which would create a cycle once
/// failures reference money types.
final class MoneyParseResult {
  const MoneyParseResult._(this.money, this.error, this.input, this.currency);

  /// A successful parse.
  factory MoneyParseResult.success(Money money) =>
      MoneyParseResult._(money, null, null, money.currency);

  /// A rejected parse, carrying enough context to build a user message.
  factory MoneyParseResult.failure(
    MoneyParseError error, {
    required String input,
    required CurrencyCode currency,
  }) => MoneyParseResult._(null, error, input, currency);

  /// The parsed amount, or null when [isSuccess] is false.
  final Money? money;

  /// The reason for failure, or null on success.
  final MoneyParseError? error;

  /// The original input, kept for error reporting.
  final String? input;

  /// The currency the parse was attempted in.
  final CurrencyCode? currency;

  /// True when parsing produced a [money] value.
  bool get isSuccess => money != null;

  @override
  String toString() => isSuccess
      ? 'MoneyParseResult.success($money)'
      : 'MoneyParseResult.$error';
}

/// Thrown when an arithmetic or comparison mixes two currencies.
///
/// This is a programmer error, not a user-facing failure — it means the domain
/// received amounts that should have been converted or kept separate first.
final class CurrencyMismatchError extends Error {
  CurrencyMismatchError(this.expected, this.actual);

  final CurrencyCode expected;
  final CurrencyCode actual;

  @override
  String toString() =>
      'CurrencyMismatchError: cannot mix ${expected.code} with ${actual.code}. '
      'Convert explicitly before combining amounts.';
}
