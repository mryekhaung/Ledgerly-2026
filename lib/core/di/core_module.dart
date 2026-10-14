import 'package:drift/drift.dart' show QueryExecutor;
import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/connection/database_connection.dart';
import 'package:ledgerly/core/database/daos/accounts_dao.dart';
import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/core/database/daos/categories_dao.dart';
import 'package:ledgerly/core/database/daos/transactions_dao.dart';

/// Registers the app-wide database and the Drift-backed datasources.
///
/// `core/` sits below every feature, so this module is registered first and the
/// feature modules depend on what it puts in the locator
/// (`docs/Architecture.md` §10).
///
/// The database is a **lazy singleton**: opening it (and running `onCreate`)
/// costs real time on first launch, and nothing should pay that before a screen
/// actually reads data.
void registerCoreModule(
  GetIt getIt, {
  QueryExecutorFactory? connectionFactory,
}) {
  // The factory is injectable so a test or a `dev` build can substitute an
  // in-memory executor without this module knowing about `drift/native`
  // (`docs/Architecture.md` §10 — environments choose implementations).
  final factory = connectionFactory ?? openOnDeviceDatabase;

  getIt.registerLazySingleton<AppDatabase>(
    () => AppDatabase(factory()),
    dispose: (database) => database.close(),
  );

  getIt.registerLazySingleton<CategoriesDao>(
    () => getIt<AppDatabase>().categoriesDao,
  );
  getIt.registerLazySingleton<TransactionsDao>(
    () => getIt<AppDatabase>().transactionsDao,
  );
  getIt.registerLazySingleton<AccountsDao>(
    () => getIt<AppDatabase>().accountsDao,
  );
  getIt.registerLazySingleton<AppSettingsDao>(
    () => getIt<AppDatabase>().appSettingsDao,
  );
}

/// Builds the [QueryExecutor] the database opens with.
///
/// A typedef rather than a bare `QueryExecutor Function()` so the intent is
/// nameable at a call site and a fake is obvious to read.
typedef QueryExecutorFactory = QueryExecutor Function();
