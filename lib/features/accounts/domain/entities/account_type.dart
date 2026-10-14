/// Categorisation for an account (e.g. Cash, Bank, Credit Card, Savings, E-Wallet).
///
/// Pure Dart: no Flutter, no Drift (docs/Agent.md §3.1).
library;

/// The type of an account.
enum AccountType {
  /// Physical cash or personal wallet.
  cash,

  /// Checking or standard bank account.
  bank,

  /// Credit card or line of credit (can be negative).
  credit,

  /// Savings or deposit account.
  savings,

  /// Digital e-wallet (e.g. KBZPay, WavePay, TrueMoney).
  ewallet;

  /// Resolves an [AccountType] from its stored name.
  static AccountType? tryParse(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final type in AccountType.values) {
      if (type.name == normalized) return type;
    }
    return null;
  }

  /// The stable storage value.
  String get storageValue => name;

  /// Default icon catalog key for this account type.
  String get defaultIconKey => switch (this) {
    AccountType.cash => 'wallet',
    AccountType.bank => 'account_balance',
    AccountType.credit => 'credit_card',
    AccountType.savings => 'savings',
    AccountType.ewallet => 'phone_android',
  };
}
