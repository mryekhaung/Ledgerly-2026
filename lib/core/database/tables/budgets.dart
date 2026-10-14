import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/tables/categories.dart';
import 'package:ledgerly/core/database/tables/common_columns.dart';

/// A spending cap allocated to a category or total period spending.
///
/// Spec: `docs/DataModel.md` §8.
@TableIndex(
  name: 'idx_budgets_list',
  columns: {#deletedAt, #isArchived, #sortOrder},
)
@TableIndex(name: 'idx_budgets_period', columns: {#periodId, #deletedAt})
@TableIndex(name: 'idx_budgets_category', columns: {#categoryId, #deletedAt})
@DataClassName('BudgetRow')
class Budgets extends Table with CommonColumns {
  /// Category id this budget caps, or null for an overall total period budget.
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// Budget period id (e.g. `'2026-10'`), or null if recurring monthly.
  TextColumn get periodId => text().nullable()();

  /// Budget limit in minor units (unsigned).
  IntColumn get amountMinor => integer()();

  /// ISO currency code lowercase.
  TextColumn get currency => text()();

  /// Warning alert threshold percentage (0.1 to 1.0, default 0.8 = 80%).
  RealColumn get alertThreshold => real().withDefault(const Constant(0.8))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
