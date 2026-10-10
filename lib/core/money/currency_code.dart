/// ISO 4217 currency codes supported by the app.
///
/// Deliberately a closed enum rather than a free-form string: it keeps
/// [Money] type-safe, makes the supported set explicit, and lets the
/// formatter hold per-currency metadata (exponent, symbol) in one place.
///
/// Myanmar Kyat is first because it is the primary market; JPY second.
enum CurrencyCode {
  mmk(code: 'MMK', symbol: 'Ks', exponent: 0, decimalSeparator: '.'),
  jpy(code: 'JPY', symbol: '¥', exponent: 0, decimalSeparator: '.'),

  // exponent 2 — most world currencies
  usd(code: 'USD', symbol: r'$', exponent: 2, decimalSeparator: '.'),
  eur(code: 'EUR', symbol: '€', exponent: 2, decimalSeparator: ','),
  gbp(code: 'GBP', symbol: '£', exponent: 2, decimalSeparator: '.'),
  sgd(code: 'SGD', symbol: r'S$', exponent: 2, decimalSeparator: '.'),
  thb(code: 'THB', symbol: '฿', exponent: 2, decimalSeparator: '.'),
  cny(code: 'CNY', symbol: '¥', exponent: 2, decimalSeparator: '.'),
  krw(code: 'KRW', symbol: '₩', exponent: 0, decimalSeparator: '.'),
  inr(code: 'INR', symbol: '₹', exponent: 2, decimalSeparator: '.');

  const CurrencyCode({
    required this.code,
    required this.symbol,
    required this.exponent,
    required this.decimalSeparator,
  });

  /// ISO 4217 alphabetic code, e.g. `MMK`.
  final String code;

  /// Short display symbol used in the UI, e.g. `Ks`.
  final String symbol;

  /// Number of minor units per major unit. 0 for MMK/JPY/KRW, 2 for the rest.
  ///
  /// This is why [Money] stores an integer: `amountMinor` is always whole units
  /// of the smallest denomination.
  final int exponent;

  /// Decimal separator for this locale/currency when rendering.
  final String decimalSeparator;

  /// Resolves a [CurrencyCode] from its ISO code, case-insensitively.
  ///
  /// Returns null for unknown codes so callers can map to a `ValidationFailure`
  /// instead of silently defaulting (important for CSV import).
  static CurrencyCode? tryParse(String code) {
    final normalized = code.trim().toUpperCase();
    for (final currency in CurrencyCode.values) {
      if (currency.code == normalized) return currency;
    }
    return null;
  }
}
