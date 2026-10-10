import 'package:get_it/get_it.dart';
import 'package:ledgerly/app/di/app_environment.dart';

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

  // --- Feature modules (Phase 1+) ---
  // registerTransactionsModule(getIt);
  // registerCategoriesModule(getIt);
  // registerSettingsModule(getIt);
}

/// Resets the locator. Test-only, so a suite can start from a clean container.
Future<void> resetDependencies() => getIt.reset();
