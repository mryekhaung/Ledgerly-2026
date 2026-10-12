import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/accounts_dao.dart';
import 'package:ledgerly/core/database/daos/categories_dao.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/daos/transactions_dao.dart';
import 'package:ledgerly/core/database/seed.dart';
import 'package:ledgerly/core/utils/local_date.dart';

/// Shared harness for the DAO tests.
///
/// Every test opens its own in-memory database, so `onCreate` runs from scratch
/// and no test can observe another's rows. The `FixedClock` means an assertion on
/// `updatedAt` can name an exact millisecond instead of racing the wall clock.
///
/// Not a `_test.dart` file itself — `flutter test` would otherwise run it as a
/// suite with no tests and report a failure.
class DbHarness {
  DbHarness({int startMillis = 1000})
    : clock = FixedClock(startMillis),
      db = AppDatabase(NativeDatabase.memory()) {
    categories = CategoriesDao(db, clock: clock);
    transactions = TransactionsDao(db, clock: clock);
    accounts = AccountsDao(db, clock: clock);
  }

  final FixedClock clock;
  final AppDatabase db;
  late final CategoriesDao categories;
  late final TransactionsDao transactions;
  late final AccountsDao accounts;

  /// Closes the database. Registered with `addTearDown` by [useDbHarness].
  Future<void> dispose() => db.close();
}

/// Creates a harness and arranges for it to be closed after the test body runs.
///
/// A leaked `NativeDatabase` keeps a file handle (and on web, an IndexedDB
/// connection) alive past the test, which shows up later as a hang rather than a
/// failure — so closing is wired here rather than left to each test.
DbHarness useDbHarness({int startMillis = 1000}) {
  final harness = DbHarness(startMillis: startMillis);
  addTearDown(harness.dispose);
  return harness;
}

/// Counts rows in [table] including soft-deleted ones.
///
/// `select(table).get()` cannot be used to prove a soft delete did not remove the
/// row, because the ordinary reads filter `deleted_at`. Reading via `selectOnly`
/// with no `where` sees the physical rows.
Future<int> physicalRowCount(
  AppDatabase db,
  TableInfo<Table, dynamic> table,
) async {
  final rows = await db.selectOnly(table).get();
  return rows.length;
}

/// Looks a raw column up by name, bypassing the DAO's filters and converters.
///
/// Used to assert what is *actually on disk* (e.g. the packed `date` integer),
/// which the typed read path hides behind `LocalDateConverter`.
Future<Object?> rawValue(
  AppDatabase db,
  String table,
  String column,
  String id,
) async {
  final row = await db
      .customSelect(
        'SELECT $column FROM $table WHERE id = ?',
        variables: [Variable<String>(id)],
      )
      .getSingleOrNull();
  return row?.data.values.first;
}

/// The seeded default category with [name], looked up by the *active* query.
Future<Category> seededCategory(CategoriesDao dao, String name) async {
  final all = await dao.watchAll().first;
  return all.firstWhere((c) => c.name == name);
}

/// Seeds the default categories and returns them.
Future<List<Category>> seedAndRead(AppDatabase db, CategoriesDao dao) async {
  await seedDefaults(db);
  return dao.watchAll().first;
}

/// A date inside a 31-day month, so day arithmetic in a test cannot silently
/// overflow into the next month.
LocalDate october(int day) => LocalDate(2026, 10, day);

/// The month a `watchMonth` call is anchored to.
LocalDate get octoberMonth => LocalDate(2026, 10, 1);
