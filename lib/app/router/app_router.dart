import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:material_ui/material_ui.dart';

/// Builds the app's router.
///
/// Phase 0 scope: the **skeleton only** — a shell route with placeholder pages so
/// navigation, deep links, and the responsive shell can be exercised before any
/// feature exists (Roadmap Phase 0, docs/Architecture.md §9).
///
/// Feature pages replace the placeholders one roadmap item at a time; the route
/// table shape stays the same.
///
/// Auth/onboarding guards are added in Phase 2 via `redirect` (docs/Auth.md).
GoRouter createRouter({String initialLocation = AppRoutes.calendar}) {
  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: false,
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) => _PlaceholderShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.calendar,
            name: AppRoutes.calendarName,
            builder: (context, state) => const _PlaceholderPage(
              titleKey: 'navigation.calendar',
              icon: Icons.calendar_today_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.insights,
            name: AppRoutes.insightsName,
            builder: (context, state) => const _PlaceholderPage(
              titleKey: 'navigation.insights',
              icon: Icons.pie_chart_outline,
            ),
          ),
          GoRoute(
            path: AppRoutes.categories,
            name: AppRoutes.categoriesName,
            builder: (context, state) => const _PlaceholderPage(
              titleKey: 'navigation.categories',
              icon: Icons.category_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: AppRoutes.settingsName,
            builder: (context, state) => const _PlaceholderPage(
              titleKey: 'navigation.settings',
              icon: Icons.settings_outlined,
            ),
          ),
        ],
      ),

      // Add / edit transaction are top-level (outside the shell) so they can be
      // presented as a full-screen page on compact and a centered modal page on
      // medium+ (docs/Platform.md §5). Phase 1.
      GoRoute(
        path: AppRoutes.transactionNew,
        name: AppRoutes.transactionNewName,
        builder: (context, state) => const _PlaceholderPage(
          titleKey: 'navigation.calendar',
          icon: Icons.add,
        ),
      ),
    ],
  );
}

/// Phase 0 shell: renders [child] without nav chrome.
///
/// The real `AdaptiveNav` (glass tab bar / M3 NavigationBar / rail / sidebar)
/// lands with the design-system widgets in Phase 0's final item — this exists so
/// the router and shell wiring are provably correct before then.
class _PlaceholderShell extends StatelessWidget {
  const _PlaceholderShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Phase 0 placeholder page. Shows the destination and states plainly that no
/// feature is implemented yet — no Lorem, no fake data (docs/Agent.md §8).
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.titleKey, required this.icon});

  final String titleKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('Phase 0 scaffold', style: theme.textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  '$titleKey — feature not implemented yet.\n'
                  'See docs/Roadmap.md.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
