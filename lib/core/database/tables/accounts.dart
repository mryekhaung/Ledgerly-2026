import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/tables/common_columns.dart';

/// Where money sits — a wallet, bank account, card, or e-wallet.
///
/// **Schema only in v1**: no UI, no seeds, no use cases until Phase 3
/// (`docs/Roadmap.md`). Declared now so `Transactions.accountId` has a target and
/// the v1 → v2 migration stays purely additive.
///
/// Spec: `docs/DataModel.md` §4.
@TableIndex(
  name: 'idx_accounts_list',
  columns: {#deletedAt, #isArchived, #sortOrder},
)
class Accounts extends Table with CommonColumns {
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// `cash` | `bank` | `credit` | `savings` | `ewallet`, stored as the enum name.
  TextColumn get type => text()();

  /// ISO code (`MMK`, `JPY`, `USD`, …), stored lowercase — matches
  /// `CurrencyCode.name` in `core/money`.
  TextColumn get currency => text()();

  /// Starting position in minor units.
  ///
  /// **Signed, unlike `transactions.amountMinor`** — it is a *position*, not a
  /// movement, so an account can legitimately open in debt. This is the only
  /// signed money column in the schema; see `docs/DataModel.md` §4.
  IntColumn get openingBalanceMinor => integer()();

  TextColumn get iconKey => text()();

  IntColumn get colorValue => integer()();

  /// Exclude a closed card from "net worth" totals without deleting it.
  BoolColumn get includeInTotal =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
