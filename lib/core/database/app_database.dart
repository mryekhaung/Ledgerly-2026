import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/daos/accounts_dao.dart';
import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/core/database/daos/categories_dao.dart';
import 'package:ledgerly/core/database/daos/transactions_dao.dart';
import 'package:ledgerly/core/database/tables/accounts.dart';
import 'package:ledgerly/core/database/tables/app_settings.dart';
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
  tables: [Categories, Transactions, Accounts, AppSettings],
  daos: [CategoriesDao, TransactionsDao, AccountsDao, AppSettingsDao],
)
class AppDatabase extends _$AppDatabase {
  /// Opens a database at [connection] — a file on device, or
  /// `NativeDatabase.memory()` in tests. See `connection/`.
  AppDatabase(super.connection);

  /// Current schema version. See `docs/DataModel.md` §5.
  ///
  /// v1 — initial: `categories`, `transactions`, `accounts`.
  /// v2 — `app_settings`: app-wide preferences (currency, language, theme,
  ///      week start). Purely additive — a new table, no column changes, so
  ///      existing data is untouched: one `createTable` plus its index.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // `createAll` covers tables *and* their `@TableIndex` indexes.
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // No migrations yet — v1 is the first schema. Every future change adds a
      // step here for the version it introduces:
      //
      //   if (from < 2) {
      //     await m.addColumn(transactions, transactions.someNewColumn);
      //   }
      //
      // and a case in `test/core/database/migration_test.dart` that opens a v1
      // database and upgrades it. Additive changes are preferred; a destructive
      // one needs justification in the PR and a data-preserving migration.
      if (from < 2) {
        // v2 adds only `app_settings`, so the upgrade is additive: an existing
        // v1 database keeps every category and transaction and simply gains an
        // empty preferences table. It stays empty until the user changes
        // something, and an empty table means "use the defaults" — so no
        // backfill is needed or wanted.
        await m.createTable(appSettings);
        // `createTable` emits only the `CREATE TABLE` statement — it does *not*
        // pick up `@TableIndex` declarations (only `createAll` does). An
        // upgraded database would therefore be missing `idx_settings_key` while
        // a freshly created one has it, and the two would drift apart. Declare
        // the index explicitly so both paths converge on the same schema.
        await m.createIndex(idxSettingsKey);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      // SQLite ships with foreign keys OFF, so the REFERENCES declarations in
      // `tables/` are decorative until this runs. It must be per-connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
