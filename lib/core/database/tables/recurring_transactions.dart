import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/tables/accounts.dart';
import 'package:ledgerly/core/database/tables/categories.dart';
import 'package:ledgerly/core/database/tables/common_columns.dart';

/// Recurring transactions schedule definitions (Phase 3 Item 3).
///
/// Holds recurring schedule rules for automatically or manually creating
/// transactions on a daily, weekly, monthly, or yearly basis.
@TableIndex(name: 'idx_recurring_list', columns: {#deletedAt, #isArchived})
@TableIndex(
  name: 'idx_recurring_due',
  columns: {#deletedAt, #isArchived, #nextDueDate},
)
@DataClassName('RecurringTransactionRow')
class RecurringTransactions extends Table with CommonColumns {
  /// Owning category.
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Target account (optional).
  TextColumn get accountId => text().nullable().references(Accounts, #id)();

  /// Always positive magnitude minor units.
  IntColumn get amountMinor => integer()();

  /// ISO currency code, stored lowercase — matches `CurrencyCode.name`.
  TextColumn get currency => text()();

  /// 'expense' | 'income' | 'transfer', stored as the enum name.
  TextColumn get direction => text()();

  /// Frequency interval: 'daily' | 'weekly' | 'monthly' | 'yearly'.
  TextColumn get frequency => text()();

  /// The first occurrence / start anchor date, packed `yyyyMMdd`.
  IntColumn get startDate => integer().map(const LocalDateConverter())();

  /// Optional expiration date, packed `yyyyMMdd`.
  IntColumn get endDate =>
      integer().nullable().map(const LocalDateConverter())();

  /// Next date this recurring rule should generate, packed `yyyyMMdd`.
  IntColumn get nextDueDate => integer().map(const LocalDateConverter())();

  /// The date of the last generated transaction, packed `yyyyMMdd`.
  IntColumn get lastGeneratedDate =>
      integer().nullable().map(const LocalDateConverter())();

  /// Whether the scheduler automatically creates the transaction (true)
  /// or requires manual user confirmation / notification (false).
  BoolColumn get autoAdd => boolean().withDefault(const Constant(true))();

  /// Optional free text note.
  TextColumn get note => text().nullable().withLength(max: 500)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
