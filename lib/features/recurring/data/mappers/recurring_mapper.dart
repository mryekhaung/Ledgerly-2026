import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

/// Maps between SQLite [RecurringTransactionRow] and domain [RecurringTransaction].
abstract final class RecurringMapper {
  const RecurringMapper._();

  /// Converts a Drift [RecurringTransactionRow] into a domain [RecurringTransaction].
  static RecurringTransaction toEntity(RecurringTransactionRow row) {
    return RecurringTransaction(
      id: row.id,
      categoryId: row.categoryId,
      accountId: row.accountId,
      amount: Money.minor(
        row.amountMinor,
        CurrencyCode.tryParse(row.currency) ?? CurrencyCode.mmk,
      ),
      direction:
          TransactionDirection.tryParse(row.direction) ??
          TransactionDirection.expense,
      frequency: RecurringFrequency.fromString(row.frequency),
      startDate: row.startDate,
      endDate: row.endDate,
      nextDueDate: row.nextDueDate,
      lastGeneratedDate: row.lastGeneratedDate,
      autoAdd: row.autoAdd,
      note: row.note,
      isArchived: row.isArchived,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  /// Converts a domain [RecurringTransaction] into a Drift [RecurringTransactionsCompanion] for insert/upsert.
  static RecurringTransactionsCompanion toCompanion(
    RecurringTransaction entity,
  ) {
    return RecurringTransactionsCompanion.insert(
      id: Value(entity.id),
      categoryId: entity.categoryId,
      accountId: Value(entity.accountId),
      amountMinor: entity.amountMinor,
      currency: entity.currency.code.toLowerCase(),
      direction: entity.direction.storageValue,
      frequency: entity.frequency.storageValue,
      startDate: entity.startDate,
      endDate: Value(entity.endDate),
      nextDueDate: entity.nextDueDate,
      lastGeneratedDate: Value(entity.lastGeneratedDate),
      autoAdd: Value(entity.autoAdd),
      note: Value(entity.note),
      isArchived: Value(entity.isArchived),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: Value(entity.deletedAt),
    );
  }
}
