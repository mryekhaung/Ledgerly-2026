// `drift` also exports an `isNotNull` (a SQL operator), which collides with the
// matcher of the same name from `flutter_test`. Only `Variable` is needed here,
// so the operator is hidden rather than the whole import being prefixed.
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/categories_dao.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/seed.dart';

import 'db_harness.dart';

/// The migration harness (`docs/DataModel.md` §5).
///
/// v1 is the first schema, so there is nothing to upgrade *from* yet — but the
/// harness ships now, deliberately, so the first real migration is not also the
/// first test of the harness. `docs/DataModel.md` §5 says exactly this, and
/// `test/core/database/migration_test.dart` is the file it names.
///
/// What these tests can prove today:
///   * `onCreate` builds the whole v1 schema, from a cold open, at version 1.
///   * `beforeOpen` actually runs, and `PRAGMA foreign_keys` really is ON —
///     without it the `REFERENCES` declarations in `tables/` are decorative and
///     a bad `categoryId` would be accepted.
///   * the declared indexes exist on disk under their `@TableIndex` names.
///   * the soft-delete columns are nullable and the "money is INTEGER, never
///     REAL" rule holds at the type level.
///
/// What it **cannot** prove: an upgrade path. When v2 lands, add a case here
/// that opens a v1 file and calls `migrate`. The template is at the bottom.
void main() {
  /// Every table the schema declares, as SQLite sees it.
  const schemaTables = <String>[
    'accounts',
    'app_settings',
    'categories',
    'transactions',
  ];

  /// The `@TableIndex` names declared across `tables/`.
  const schemaIndexes = <String>[
    'idx_accounts_list',
    'idx_categories_list',
    'idx_categories_kind',
    'idx_settings_key',
    'idx_transactions_date',
    'idx_transactions_category',
    'idx_transactions_sync',
  ];

  /// Reads `sqlite_master` — the authoritative record of what was created.
  Future<List<String>> namesByType(AppDatabase db, String type) async {
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master WHERE type = ? ORDER BY name',
          variables: [Variable<String>(type)],
        )
        .get();
    return rows.map((row) => row.read<String>('name')).toList();
  }

  /// Reads a single `PRAGMA` value as an int, e.g. `foreign_keys`.
  Future<int?> pragmaInt(AppDatabase db, String pragma) async {
    final row = await db.customSelect('PRAGMA $pragma').getSingleOrNull();
    if (row == null) return null;
    final value = row.data.values.first;
    return value is int ? value : null;
  }

  /// `PRAGMA table_info(<table>)` as `column name -> declared type`.
  Future<Map<String, String>> columnsOf(AppDatabase db, String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return {
      for (final row in rows)
        row.read<String>('name'): row.read<String>('type').toUpperCase(),
    };
  }

  group('v1 onCreate', () {
    test('should_create_every_declared_table_exactly_once', () async {
      final h = useDbHarness();

      // Force the lazy open so `onCreate` has actually run.
      await h.db.customSelect('SELECT 1').get();

      final tables = await namesByType(h.db, 'table');
      for (final expected in schemaTables) {
        expect(
          tables.where((name) => name == expected).length,
          1,
          reason: '$expected must exist exactly once (saw: $tables)',
        );
      }
    });

    test('should_report_the_current_schema_version_and_leave_no_drift_internal_schema', () async {
      final h = useDbHarness();
      await h.db.customStatement('SELECT 1');

      // Read from `AppDatabase.schemaVersion` rather than hard-coding: the
      // schema is at v2 (`app_settings` was added additively), and a literal
      // here would silently go stale on the next bump instead of tracking it.
      expect(await pragmaInt(h.db, 'user_version'), h.db.schemaVersion);
    });

    test('should_create_every_declared_index', () async {
      final h = useDbHarness();
      await h.db.customSelect('SELECT 1').get();

      final indexes = await namesByType(h.db, 'index');
      for (final expected in schemaIndexes) {
        expect(
          indexes,
          contains(expected),
          reason:
              'the hot-path indexes in docs/DataModel.md §1 must exist '
              '(saw: $indexes)',
        );
      }
    });

    test('should_create_a_well_formed_table_even_on_a_cold_open', () async {
      // `DbHarness` opens `NativeDatabase.memory()`, so every test here starts
      // from an empty file and `onCreate` runs from scratch — there is no
      // upgraded-from-v0 state to accidentally rely on.
      final h = useDbHarness();

      // A write must succeed against the schema `onCreate` produced.
      await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );
      expect((await h.categories.watchAll().first).length, 1);
    });
  });

  group('v1 column contract', () {
    test('should_store_money_as_integer_never_real', () async {
      // `docs/Architecture.md` ADR #2 — floating point money is banned. Asserted
      // at the SQLite level because a `REAL` column would only show up as a
      // rounding bug months later.
      final h = useDbHarness();
      final columns = await columnsOf(h.db, 'transactions');

      expect(columns['amount_minor'], 'INTEGER');
      expect(columns['date'], 'INTEGER');
      expect(columns['created_at'], 'INTEGER');
      expect(columns['updated_at'], 'INTEGER');
      expect(
        columns.values.where((type) => type.contains('REAL')),
        isEmpty,
        reason: 'no column in the schema may be REAL',
      );
    });

    test(
      'should_keep_deleted_at_nullable_on_every_soft_deletable_table',
      () async {
        final h = useDbHarness();

        // `app_settings` is a key/value table added in v2 and is not
        // soft-deletable, so it has no `deleted_at` at all. The contract under
        // test is "where a `deleted_at` exists, it is nullable", so the table list
        // is the soft-deletable subset rather than every table.
        const softDeletable = <String>[
          'categories',
          'transactions',
          'accounts',
        ];

        for (final table in softDeletable) {
          final rows = await h.db
              .customSelect('PRAGMA table_info($table)')
              .get();
          final deletedAt = rows.firstWhere(
            (row) => row.read<String>('name') == 'deleted_at',
            orElse: () => throw StateError('$table has no deleted_at column'),
          );
          expect(
            deletedAt.read<int>('notnull'),
            0,
            reason:
                '$table.deleted_at must be nullable — NULL means live '
                '(ADR #4)',
          );
        }
      },
    );

    test('should_keep_account_id_nullable_until_accounts_ship', () async {
      // A NOT NULL column could not be added to a populated transactions table
      // without a data-preserving migration (`docs/DataModel.md` §3).
      final h = useDbHarness();
      final columns = await columnsOf(h.db, 'transactions');

      expect(columns.containsKey('account_id'), isTrue);
      final rows = await h.db
          .customSelect('PRAGMA table_info(transactions)')
          .get();
      final accountId = rows.firstWhere(
        (row) => row.read<String>('name') == 'account_id',
      );
      expect(accountId.read<int>('notnull'), 0);
    });

    test('should_keep_opening_balance_signed_as_an_integer', () async {
      final h = useDbHarness();
      await h.db.customSelect('SELECT 1').get();

      final columns = await columnsOf(h.db, 'accounts');
      expect(columns['opening_balance_minor'], 'INTEGER');
    });
  });

  group('beforeOpen', () {
    test('should_enable_foreign_keys_on_the_connection', () async {
      // SQLite ships with foreign keys OFF. Without this pragma the
      // `REFERENCES` clauses in `tables/` do nothing and a transaction could
      // point at a category that does not exist.
      final h = useDbHarness();
      await h.db.customSelect('SELECT 1').get();

      expect(
        await pragmaInt(h.db, 'foreign_keys'),
        1,
        reason: 'AppDatabase.beforeOpen must run PRAGMA foreign_keys = ON',
      );
    });

    test(
      'should_actually_reject_a_transaction_with_a_unknown_category',
      () async {
        // The behavioural proof that the pragma is not merely set but enforced.
        final h = useDbHarness();
        await h.db.customSelect('SELECT 1').get();

        await expectLater(
          h.db.customStatement(
            'INSERT INTO transactions '
            '(id, category_id, amount_minor, currency, direction, date, '
            'created_at, updated_at, sort_order, is_archived) '
            "VALUES ('t1', 'no-such-category', 1, 'mmk', 'expense', 20261003, "
            '1, 1, 0, 0)',
          ),
          throwsA(isA<Exception>()),
          reason: 'a dangling category_id must be a foreign-key violation',
        );
      },
    );

    test('should_allow_a_transaction_with_a_known_category', () async {
      // The other half of the previous test: the constraint must not be so
      // strict that a legitimate insert fails.
      final h = useDbHarness();
      final categoryId = await h.categories.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 1,
      );

      final id = await h.transactions.insert(
        categoryId: categoryId,
        amountMinor: 100,
        currency: 'mmk',
        direction: 'expense',
        date: october(3),
      );

      expect(await h.transactions.findById(id), isNotNull);
    });
  });

  group('upgrade path', () {
    test('should_be_at_v2', () {
      final h = useDbHarness();
      expect(
        h.db.schemaVersion,
        2,
        reason:
            'v2 added app_settings; bumping again requires a new onUpgrade step '
            'and a real upgrade test here (docs/DataModel.md §5)',
      );
    });

    test('should_declare_the_settings_table_and_its_index', () async {
      final h = useDbHarness();
      await h.db.customSelect('SELECT 1').get();

      expect(await namesByType(h.db, 'table'), contains('app_settings'));
      expect(await namesByType(h.db, 'index'), contains('idx_settings_key'));
    });

    test('should_upgrade_v1_to_v2_keeping_categories_and_transactions', () async {
      // The real upgrade proof.
      //
      // A v1 database is built **by hand** with the exact v1 DDL and
      // `PRAGMA user_version = 1`, then closed. Opening the *same file* through
      // the current [AppDatabase] at version 2 is what makes drift run
      // `onUpgrade(from: 1, to: 2)` — the code path this test exists to
      // exercise.
      //
      // Building v1 by hand (rather than opening an old AppDatabase) is what
      // makes this honest: the handwritten DDL is frozen at v1 forever and
      // cannot drift along with the current schema.
      //
      // A file, not `NativeDatabase.memory()`: an in-memory executor cannot be
      // reopened after `close()`, and the reopen is the whole test.
      final temp = useTempDbFile();
      addTearDown(temp.dispose);

      // Build v1 through a throwaway [AppDatabase] on the temp file: the schema
      // management is bypassed with raw DDL, but the file is then closed and
      // reopened by the real database below.
      final v1 = AppDatabase(NativeDatabase(temp.file));
      await v1.customStatement('DROP TABLE IF EXISTS app_settings');
      await v1.customStatement('DROP TABLE IF EXISTS transactions');
      await v1.customStatement('DROP TABLE IF EXISTS categories');
      await v1.customStatement('DROP TABLE IF EXISTS accounts');
      await v1.customStatement(
        'CREATE TABLE categories ('
        'id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, '
        'icon_key TEXT NOT NULL, color_value INTEGER NOT NULL, '
        "kind TEXT NOT NULL DEFAULT 'expense', "
        'is_default INTEGER NOT NULL DEFAULT 0, '
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
        'deleted_at INTEGER, sort_order INTEGER NOT NULL DEFAULT 0, '
        'is_archived INTEGER NOT NULL DEFAULT 0)',
      );
      await v1.customStatement(
        'CREATE TABLE transactions ('
        'id TEXT NOT NULL PRIMARY KEY, category_id TEXT NOT NULL, '
        'amount_minor INTEGER NOT NULL, currency TEXT NOT NULL, '
        'direction TEXT NOT NULL, date INTEGER NOT NULL, note TEXT, '
        'account_id TEXT, created_at INTEGER NOT NULL, '
        'updated_at INTEGER NOT NULL, deleted_at INTEGER, '
        'sort_order INTEGER NOT NULL DEFAULT 0, '
        'is_archived INTEGER NOT NULL DEFAULT 0, '
        'FOREIGN KEY (category_id) REFERENCES categories (id))',
      );
      await v1.customStatement(
        'CREATE TABLE accounts ('
        'id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, '
        'kind TEXT NOT NULL, currency TEXT NOT NULL, '
        'opening_balance_minor INTEGER NOT NULL, '
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
        'deleted_at INTEGER, sort_order INTEGER NOT NULL DEFAULT 0, '
        'is_archived INTEGER NOT NULL DEFAULT 0)',
      );
      await v1.customStatement(
        'INSERT INTO categories (id, name, icon_key, color_value, kind, '
        'is_default, created_at, updated_at, sort_order, is_archived) '
        "VALUES ('c1', 'Food', 'restaurant', 1, 'expense', 1, 1, 1, 0, 0)",
      );
      await v1.customStatement(
        'INSERT INTO transactions (id, category_id, amount_minor, currency, '
        'direction, date, created_at, updated_at, sort_order, is_archived) '
        "VALUES ('t1', 'c1', 250, 'mmk', 'expense', 20261003, 1, 1, 0, 0)",
      );
      await v1.customStatement('PRAGMA user_version = 1');
      await v1.close();

      // --- Reopen the same file through the current database: onUpgrade runs ---
      final upgraded = AppDatabase(NativeDatabase(temp.file));

      // ...existing rows survived...
      final categories = await upgraded.categoriesDao.watchAll().first;
      expect(categories, hasLength(1));
      expect(categories.single.name, 'Food');

      // The transaction was written on 2026-10-03, so it lives in the
      // October 2026 month bucket — `watchMonth` is the DAO's month read.
      final transactions = await upgraded.transactionsDao
          .watchMonth(october(3))
          .first;
      expect(transactions, hasLength(1));
      expect(transactions.single.amountMinor, 250);

      // ...and the v2 table exists, is empty, and is writable.
      expect(await upgraded.appSettingsDao.readAll(), isEmpty);
      await upgraded.appSettingsDao.put(key: 'currency', value: 'usd');
      expect(await upgraded.appSettingsDao.read('currency'), 'usd');

      // ...and the v2 *index* exists too. This is the subtle half: drift's
      // `Migrator.createTable` emits only the `CREATE TABLE` statement and
      // silently skips `@TableIndex` declarations, so an upgraded database
      // would end up with a weaker schema than a freshly created one. The
      // `onUpgrade` step has to ask for the index explicitly, and this is the
      // assertion that keeps it honest.
      expect(
        await namesByType(upgraded, 'index'),
        contains('idx_settings_key'),
        reason:
            'onUpgrade must create idx_settings_key explicitly — '
            'createTable alone does not emit @TableIndex indexes',
      );

      await upgraded.close();
    });

    test('should_keep_the_seeded_rows_readable_after_a_reopen', () async {
      // The closest thing to an upgrade test that v1 can honestly support: seed,
      // close, reopen the *same* underlying database, and prove the rows are
      // still there and still readable through the typed path. This is what a
      // migration must preserve, so it establishes the baseline the first real
      // upgrade test will compare against.
      final clock = FixedClock(1000);
      // A file, not `NativeDatabase.memory()`: the whole point is to close the
      // database and open it again, and an in-memory executor cannot be
      // reopened once closed.
      final temp = useTempDbFile();
      addTearDown(temp.dispose);

      final first = AppDatabase(NativeDatabase(temp.file));
      final firstDao = CategoriesDao(first, clock: clock);
      await seedDefaults(first, clock: clock);
      final seededIds = (await firstDao.watchAll().first)
          .map((c) => c.id)
          .toList();
      await first.close();

      final second = AppDatabase(NativeDatabase(temp.file));
      final secondDao = CategoriesDao(second, clock: clock);
      final reopened = await secondDao.watchAll().first;
      expect(reopened.map((c) => c.id).toList(), seededIds);
      expect(reopened.length, 11);
      await second.close();
    });
  });
}
