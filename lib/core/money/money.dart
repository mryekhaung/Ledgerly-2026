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
  /// Use this only at boundaries (parsing user input, reading a CSV). Internally
  /// the app always works in minor units.
  factory Money.fromMajor(num major, CurrencyCode currency) {
    final scaled = major * _pow10(currency.exponent);
    // `round()` on a double is half-away-from-zero in Dart.
    return Money.minor(scaled.round(), currency);
  }

  /// Creates an amount by parsing a decimal string in the given currency.
  ///
  /// Returns null when [input] is not a valid number, so callers can produce a
  /// `ValidationFailure` rather than an exception (docs/Architecture.md §8).
  /// Accepts `1,234.56`, `1234.56`, `-12`, and a leading `+`.
  static Money? tryParse(String input, CurrencyCode currency) {
    final cleaned = input.trim().replaceAll(',', '').replaceAll('\u00A0', '');
    if (cleaned.isEmpty) return null;

    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;

    return Money.fromMajor(parsed, currency);
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
  Money operator *(int factor) =>
      Money.minor(amountMinor * factor, currency);

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
    return '$sign$major.${padded} ${currency.code}';
  }

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw CurrencyMismatchError(currency, other.currency);
    }
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
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
