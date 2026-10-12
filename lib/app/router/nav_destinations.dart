import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// One primary destination in the app shell.
///
/// The single source of truth for the navigation bar, rail and sidebar: every
/// surface iterates [NavDestination.all], so a destination can never appear in
/// one layout and be missing from another.
///
/// Icons are paired — filled for the selected state, outlined for the rest —
/// because Design.md §5.10 requires an active icon to read as active without
/// relying on colour alone (`docs/Design.md` §2 a11y: never colour-only).
enum NavDestination {
  /// The calendar — the app's home screen and default route.
  calendar(
    route: AppRoutes.calendar,
    labelKey: 'navigationCalendar',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
  ),

  /// Spending insights.
  insights(
    route: AppRoutes.insights,
    labelKey: 'navigationInsights',
    icon: Icons.pie_chart_outline,
    selectedIcon: Icons.pie_chart,
  ),

  /// Category management.
  categories(
    route: AppRoutes.categories,
    labelKey: 'navigationCategories',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
  ),

  /// App settings.
  settings(
    route: AppRoutes.settings,
    labelKey: 'navigationSettings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const NavDestination({
    required this.route,
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
  });

  /// The `go_router` path this destination navigates to.
  final String route;

  /// ARB key for the destination label.
  ///
  /// A key rather than a resolved string: destinations are `const`, so they
  /// cannot hold a `BuildContext`-dependent translation. Resolve with
  /// [label] where a context is available.
  final String labelKey;

  /// Icon shown when this destination is not selected.
  final IconData icon;

  /// Icon shown when this destination is selected.
  final IconData selectedIcon;

  /// The localized label for this destination.
  String label(String Function(String key) strings) => strings(labelKey);

  /// Every destination, in display order.
  ///
  /// Order matters: it is the tab order in the bar and the top-to-bottom order
  /// in a rail or sidebar. Calendar is first because it is the home screen.
  static const List<NavDestination> all = <NavDestination>[
    calendar,
    insights,
    categories,
    settings,
  ];

  /// The destination whose route matches [location], or null.
  ///
  /// Matches on the **first path segment** so a nested page keeps its parent
  /// destination selected: on `/transactions/new` nothing matches, but on
  /// `/settings/currency` Settings stays lit — which is what the user expects
  /// from a section they navigated into.
  static NavDestination? fromLocation(String location) {
    for (final destination in all) {
      if (destination.route == AppRoutes.calendar) {
        // The calendar is `/`, so it matches only an exact root — otherwise
        // every path would match it by prefix.
        if (location == '/' || location.isEmpty) return destination;
        continue;
      }
      if (location == destination.route ||
          location.startsWith('${destination.route}/')) {
        return destination;
      }
    }
    return null;
  }
}
