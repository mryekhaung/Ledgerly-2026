import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/daos/accounts_dao.dart';
import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/core/database/daos/budgets_dao.dart';
import 'package:ledgerly/core/database/daos/categories_dao.dart';
import 'package:ledgerly/core/database/daos/transactions_dao.dart';
import 'package:ledgerly/core/database/tables/accounts.dart';
import 'package:ledgerly/core/database/tables/app_settings.dart';
import 'package:ledgerly/core/database/tables/budgets.dart';
import 'package:ledgerly/core/database/tables/categories.dart';
import 'package:ledgerly/core/database/tables/common_columns.dart';
import 'package:ledgerly/core/database/tables/transactions.dart';
import 'package:ledgerly/core/database/uuid.dart';
import 'package:ledgerly/core/utils/local_date.dart';

part 'app_database.g.dart';

/// The on-device SQLite database — the app's source of truth.
///
/// Local-first by design (`docs/Architecture.md` ADR #1): every feature must work
/// with no network. The remote store (v0.4) syncs *from* here, never the reverse.
///
/// Schema spec: `docs/DataModel.md`. Bump [schemaVersion] **only** together with an
/// `onUpgrade` step and a matching `migration_test.dart` case.
@DriftDatabase(
  tables: [Categories, Transactions, Accounts, AppSettings, Budgets],
  daos: [
    CategoriesDao,
    TransactionsDao,
    AccountsDao,
    AppSettingsDao,
    BudgetsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens a database at [connection] — a file on device, or
  /// `NativeDatabase.memory()` in tests. See `connection/`.
  AppDatabase(super.connection);

  /// Current schema version. See `docs/DataModel.md` §5.
  ///
  /// v1 — initial: `categories`, `transactions`, `accounts`.
  /// v2 — `app_settings`: app-wide preferences.
  /// v3 — `budgets`: spending limits per category and total period budgets.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // `createAll` covers tables *and* their `@TableIndex` indexes.
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(appSettings);
        await m.createIndex(idxSettingsKey);
      }
      if (from < 3) {
        await m.createTable(budgets);
        await m.createIndex(idxBudgetsList);
        await m.createIndex(idxBudgetsPeriod);
        await m.createIndex(idxBudgetsCategory);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      // SQLite ships with foreign keys OFF, so the REFERENCES declarations in
      // `tables/` are decorative until this runs. It must be per-connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
