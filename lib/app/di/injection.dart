import 'package:get_it/get_it.dart';
import 'package:ledgerly/app/di/app_environment.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/seed.dart';
import 'package:ledgerly/core/di/core_module.dart';
import 'package:ledgerly/features/accounts/di/accounts_module.dart';
import 'package:ledgerly/features/auth/di/auth_module.dart';
import 'package:ledgerly/features/budgets/di/budgets_module.dart';
import 'package:ledgerly/features/categories/di/categories_module.dart';
import 'package:ledgerly/features/data_transfer/di/data_transfer_module.dart';
import 'package:ledgerly/features/insights/di/insights_module.dart';
import 'package:ledgerly/features/profile/di/profile_module.dart';
import 'package:ledgerly/features/recurring/di/recurring_module.dart';
import 'package:ledgerly/features/settings/di/settings_module.dart';
import 'package:ledgerly/features/transactions/di/transactions_module.dart';

/// The app-wide service locator.
///
/// **Scope rule** (docs/Architecture.md §10): get_it wires `data` and `domain`
/// only — datasources, repositories, use cases. Presentation state lives in
/// Riverpod, and providers read use cases from here via a thin bridge:
///
/// ```dart
/// final addTransactionProvider = Provider((_) => getIt<AddTransaction>());
/// ```
///
/// Registered singletons default to **lazy**, so nothing is constructed until a
/// provider actually asks for it.
final GetIt getIt = GetIt.instance;

/// Registers everything needed before the first frame.
///
/// Phase 0 registers nothing but the environment flag — feature modules are added
/// here as `registerTransactionsModule(getIt)` etc., one per roadmap item
/// (docs/Architecture.md §10).
///
/// [environment] selects implementation bindings: `dev` may use a `Noop` remote
/// datasource where `prod` uses a real one (docs/Architecture.md §10, §4).
Future<void> configureDependencies({
  required AppEnvironment environment,
}) async {
  // Guard against double-initialisation in tests that call this twice.
  if (getIt.isRegistered<AppEnvironment>()) {
    return;
  }

  getIt.registerSingleton<AppEnvironment>(environment);

  // --- Feature modules (Phase 1) ---
  // Order matters: `core` owns the database and every feature module resolves
  // it from the locator, so it must be registered first
  // (docs/Architecture.md §10).
  registerCoreModule(getIt);
  registerCategoriesModule(getIt);
  registerTransactionsModule(getIt);
  registerInsightsModule(getIt);
  // Registered last because its only cross-feature dependency is the database;
  // nothing else depends on it at wiring time, and it must be available before
  // the first frame reads a currency or a theme (`app.dart`).
  registerSettingsModule(getIt);
  // Shares the `app_settings` DAO with the settings module but nothing else, so
  // it registers independently and either can be removed without the other.
  registerProfileModule(getIt);
  registerAuthModule(getIt);
  registerDataTransferModule(getIt);
  registerAccountsModule(getIt);
  registerBudgetsModule(getIt);
  registerRecurringModule(getIt);

  // Seed the starter categories on a genuinely fresh install.
  //
  // Runs *after* the modules so the database is resolvable, and it deliberately
  // forces the (otherwise lazy) singleton open: a first launch with an empty
  // category picker is a broken-looking app, and waiting until the first screen
  // reads would seed behind a spinner. [seedDefaults] itself is idempotent —
  // it no-ops when the table already has rows, so this is safe on every launch
  // and cannot resurrect categories the user deleted on purpose.
  await seedDefaults(getIt<AppDatabase>());
}

/// Resets the locator. Test-only, so a suite can start from a clean container.
Future<void> resetDependencies() => getIt.reset();
