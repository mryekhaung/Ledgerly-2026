import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/app.dart';
import 'package:ledgerly/app/di/app_environment.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/app/router/app_router.dart';

/// Entry point.
///
/// Order matters: DI is configured **before** the first frame so Riverpod
/// providers can synchronously resolve use cases from get_it
/// (docs/Architecture.md §10).
///
/// NOTE: no `print()` and no try/catch here — errors are surfaced through the
/// AppLogger abstraction plus a global guard (docs/Conventions.md §4).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies(environment: AppEnvironment.fromDartDefine());

  // Dev-only: `--dart-define=INITIAL_ROUTE=/settings` opens straight on a screen
  // that has no navigation entry point yet. Null in a normal run (and always in
  // prod), in which case the router's own default applies.
  final initialRoute = AppEnvironment.initialRouteFromDartDefine();

  runApp(
    ProviderScope(
      child: LedgerlyApp(
        router: initialRoute == null ? null : createRouter(initialLocation: initialRoute),
      ),
    ),
  );
}
