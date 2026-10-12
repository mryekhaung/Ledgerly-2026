import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/tables/accounts.dart';
import 'package:ledgerly/core/database/tables/categories.dart';
import 'package:ledgerly/core/database/tables/common_columns.dart';

/// One money movement. The centre of the app.
///
/// Spec: `docs/DataModel.md` §3.
@TableIndex(name: 'idx_transactions_date', columns: {#date, #deletedAt})
@TableIndex(
  name: 'idx_transactions_category',
  columns: {#categoryId, #date, #deletedAt},
)
@TableIndex(name: 'idx_transactions_sync', columns: {#deletedAt, #date})
class Transactions extends Table with CommonColumns {
  /// Owning category. `ON DELETE` never fires in practice — the app soft-deletes.
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Owning account, once accounts ship in v0.3. Nullable so a v1 row is
  /// category-only; a NOT NULL column could not be added to a populated table
  /// without a data-preserving migration.
  TextColumn get accountId => text().nullable().references(Accounts, #id)();

  /// **Always positive** — direction lives in [direction], never in the sign.
  ///
  /// A negative amount plus an expense direction is double-negation, which
  /// produces sign bugs at every aggregation. Keeping the magnitude unsigned
  /// makes `SUM(amount_minor)` over a direction-filtered query the only correct
  /// form. Range is validated in the domain against `Money.maxDigits`.
  IntColumn get amountMinor => integer()();

  /// ISO currency code, stored lowercase — matches `CurrencyCode.name`.
  TextColumn get currency => text()();

  /// `expense` | `income` | `transfer`, stored as the enum name.
  TextColumn get direction => text()();

  /// The business day the user picked, packed `yyyyMMdd`.
  ///
  /// A *day*, not an instant: storing a timestamp makes a 23:30 entry on the 31st
  /// appear in the following month for some timezones. `createdAt` holds the
  /// instant separately.
  IntColumn get date => integer().map(const LocalDateConverter())();

  TextColumn get note => text().nullable().withLength(max: 500)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
