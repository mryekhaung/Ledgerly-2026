import 'package:drift/drift.dart' show Value;
import 'package:ledgerly/core/database/app_database.dart' as db;
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_type.dart';

/// Translates between Drift's [db.Account] row class and the pure-Dart [Account] domain entity.
abstract final class AccountMapper {
  const AccountMapper._();

  /// Converts a Drift database row to domain [Account].
  static Account toEntity(db.Account row, {int? currentBalanceMinor}) {
    return Account(
      id: row.id,
      name: row.name,
      type: AccountType.tryParse(row.type) ?? AccountType.cash,
      currency: CurrencyCode.tryParse(row.currency) ?? CurrencyCode.mmk,
      openingBalanceMinor: row.openingBalanceMinor,
      currentBalanceMinor: currentBalanceMinor ?? row.openingBalanceMinor,
      iconKey: row.iconKey,
      colorValue: row.colorValue,
      sortOrder: row.sortOrder,
      isArchived: row.isArchived,
      includeInTotal: row.includeInTotal,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  /// Converts an [Account] entity to Drift insert companion.
  static db.AccountsCompanion toInsertCompanion(
    Account account, {
    required int nowUtcMillis,
  }) {
    return db.AccountsCompanion.insert(
      id: Value(account.id),
      name: account.name,
      type: account.type.storageValue,
      currency: account.currency.name,
      openingBalanceMinor: account.openingBalanceMinor,
      iconKey: account.iconKey,
      colorValue: account.colorValue,
      sortOrder: Value(account.sortOrder),
      includeInTotal: Value(account.includeInTotal),
      isArchived: Value(account.isArchived),
      createdAt: nowUtcMillis,
      updatedAt: nowUtcMillis,
    );
  }

  /// Converts an [Account] entity to Drift update companion.
  static db.AccountsCompanion toUpdateCompanion(
    Account account, {
    required int nowUtcMillis,
  }) {
    return db.AccountsCompanion(
      name: Value(account.name),
      type: Value(account.type.storageValue),
      currency: Value(account.currency.name),
      openingBalanceMinor: Value(account.openingBalanceMinor),
      iconKey: Value(account.iconKey),
      colorValue: Value(account.colorValue),
      sortOrder: Value(account.sortOrder),
      includeInTotal: Value(account.includeInTotal),
      isArchived: Value(account.isArchived),
      updatedAt: Value(nowUtcMillis),
    );
  }
}
