import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_type.dart';

/// An account where funds are held (e.g. Wallet, Bank, Credit Card, E-Wallet).
///
/// Pure Dart: no Flutter, no Drift (docs/Agent.md §3.1, docs/Architecture.md §1).
///
/// Spec: docs/DataModel.md §4.
final class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalanceMinor,
    required this.currentBalanceMinor,
    required this.iconKey,
    required this.colorValue,
    required this.sortOrder,
    required this.isArchived,
    required this.includeInTotal,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Client-generated UUIDv4.
  final String id;

  /// Display name (e.g. "Wallet", "KBZ Bank", "KBZPay").
  final String name;

  /// Categorisation type.
  final AccountType type;

  /// ISO currency code.
  final CurrencyCode currency;

  /// Starting balance in minor units (signed: can start negative).
  final int openingBalanceMinor;

  /// Current computed balance in minor units (opening + net transaction movements).
  final int currentBalanceMinor;

  /// Icon identifier key.
  final String iconKey;

  /// ARGB32 colour value.
  final int colorValue;

  /// Ascending sort order index.
  final int sortOrder;

  /// Whether the account is archived.
  final bool isArchived;

  /// Whether this account's balance counts towards overall net worth.
  final bool includeInTotal;

  /// Milliseconds since UTC epoch.
  final int createdAt;

  /// Milliseconds since UTC epoch.
  final int updatedAt;

  /// Milliseconds since UTC epoch if soft-deleted, null otherwise.
  final int? deletedAt;

  /// Whether this account has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    CurrencyCode? currency,
    int? openingBalanceMinor,
    int? currentBalanceMinor,
    String? iconKey,
    int? colorValue,
    int? sortOrder,
    bool? isArchived,
    bool? includeInTotal,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      currentBalanceMinor: currentBalanceMinor ?? this.currentBalanceMinor,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      includeInTotal: includeInTotal ?? this.includeInTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.currency == currency &&
        other.openingBalanceMinor == openingBalanceMinor &&
        other.currentBalanceMinor == currentBalanceMinor &&
        other.iconKey == iconKey &&
        other.colorValue == colorValue &&
        other.sortOrder == sortOrder &&
        other.isArchived == isArchived &&
        other.includeInTotal == includeInTotal &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    currency,
    openingBalanceMinor,
    currentBalanceMinor,
    iconKey,
    colorValue,
    sortOrder,
    isArchived,
    includeInTotal,
    createdAt,
    updatedAt,
    deletedAt,
  );

  @override
  String toString() =>
      'Account(id: $id, name: $name, type: ${type.name}, balance: $currentBalanceMinor)';
}
