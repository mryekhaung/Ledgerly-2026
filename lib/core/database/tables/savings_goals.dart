import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/tables/accounts.dart';
import 'package:ledgerly/core/database/tables/common_columns.dart';

/// Savings goals tracking target amounts and deadlines (Phase 3 Item 4).
@TableIndex(
  name: 'idx_savings_goals_list',
  columns: {#deletedAt, #isArchived, #sortOrder},
)
@DataClassName('SavingsGoalRow')
class SavingsGoals extends Table with CommonColumns {
  /// Goal title (e.g. "Emergency Fund", "New Laptop").
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Target goal amount in minor units (unsigned).
  IntColumn get targetAmountMinor => integer()();

  /// Accumulated saved amount in minor units (unsigned).
  IntColumn get currentAmountMinor =>
      integer().withDefault(const Constant(0))();

  /// ISO currency code lowercase.
  TextColumn get currency => text()();

  /// Optional target deadline date, packed yyyyMMdd.
  IntColumn get targetDate =>
      integer().nullable().map(const LocalDateConverter())();

  /// Optional linked account.
  TextColumn get accountId => text().nullable().references(Accounts, #id)();

  /// Icon identifier key.
  TextColumn get iconKey => text().withDefault(const Constant('savings'))();

  /// Accent color 32-bit ARGB integer.
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF2E7D32))();

  /// Optional notes.
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
