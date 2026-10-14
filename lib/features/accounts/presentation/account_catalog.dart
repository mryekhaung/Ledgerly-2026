import 'package:material_ui/material_ui.dart';

/// Catalog of curated icons for accounts.
abstract final class AccountIcons {
  const AccountIcons._();

  /// Default fallback icon key.
  static const String fallbackKey = 'wallet';

  /// Selectable icon keys in display order.
  static const List<String> keys = <String>[
    'wallet',
    'account_balance',
    'credit_card',
    'savings',
    'phone_android',
    'payments',
    'local_atm',
    'currency_exchange',
    'attach_money',
    'store',
    'shopping_bag',
    'monetization_on',
  ];

  /// Resolves [key] to an [IconData], falling back to [fallbackKey].
  static IconData iconFor(String? key) => _icons[key] ?? _icons[fallbackKey]!;

  /// The default glyph.
  static IconData get defaultIcon => _icons[fallbackKey]!;

  static const Map<String, IconData> _icons = <String, IconData>{
    'wallet': Icons.account_balance_wallet_outlined,
    'account_balance': Icons.account_balance_outlined,
    'credit_card': Icons.credit_card_outlined,
    'savings': Icons.savings_outlined,
    'phone_android': Icons.phone_android_outlined,
    'payments': Icons.payments_outlined,
    'local_atm': Icons.local_atm_outlined,
    'currency_exchange': Icons.currency_exchange_outlined,
    'attach_money': Icons.attach_money_outlined,
    'store': Icons.store_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'monetization_on': Icons.monetization_on_outlined,
  };
}

/// The colour palette offered for accounts.
abstract final class AccountPalette {
  const AccountPalette._();

  /// Fallback color (jade brand).
  static const int fallbackColor = 0xFF2E7D6B;

  /// Selectable colors.
  static const List<int> colors = <int>[
    0xFF2E7D6B, // jade
    0xFF3A8FE8, // blue
    0xFF5A6FE8, // indigo
    0xFF8A5AE8, // violet
    0xFFE85D5D, // coral
    0xFFE8833A, // amber
    0xFFE8B93A, // gold
    0xFF4CAF7D, // green
    0xFF3AA6A0, // teal
    0xFFC85AE8, // magenta
    0xFFE85A9B, // pink
    0xFF455A64, // slate
  ];

  /// True when [value] is a valid non-transparent color.
  static bool isValid(int value) => value != 0 && (value >> 24) & 0xFF != 0;
}
