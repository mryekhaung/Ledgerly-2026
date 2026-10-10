import 'package:material_ui/material_ui.dart';

/// Route path + name constants. Feature-owned route files extend this
/// (docs/Architecture.md §9: go_router with typed routes).
///
/// Keeping paths in one place lets deep links (`/tx/new?date=...`) and tests
/// refer to them without string duplication.
abstract final class AppRoutes {
  const AppRoutes._();

  /// Root — the calendar/home shell.
  static const String calendar = '/';
  static const String calendarName = 'calendar';

  /// Insights (Phase 2).
  static const String insights = '/insights';
  static const String insightsName = 'insights';

  /// Categories (Phase 1).
  static const String categories = '/categories';
  static const String categoriesName = 'categories';

  /// Settings (Phase 1).
  static const String settings = '/settings';
  static const String settingsName = 'settings';

  /// Add / edit transaction (Phase 1). Dedicated page, never a dialog.
  static const String transactionNew = '/transactions/new';
  static const String transactionNewName = 'transactionNew';

  static const String transactionEdit = '/transactions/:id/edit';
  static const String transactionEditName = 'transactionEdit';

  /// Sub-route of the settings branch (Phase 1).
  static const String settingsCurrency = '/settings/currency';
  static const String settingsCurrencyName = 'settingsCurrency';
}

/// Shell destinations for the primary navigation. Rendered as a glass tab bar
/// on iOS, M3 `NavigationBar` on Android, rail/sidebar on wide windows
/// (docs/Platform.md §3).
enum AppDestination {
  /// Calendar / home.
  calendar(
    route: AppRoutes.calendar,
    labelKey: 'navigation.calendar',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
  ),

  /// Insights.
  insights(
    route: AppRoutes.insights,
    labelKey: 'navigation.insights',
    icon: Icons.pie_chart_outline,
    selectedIcon: Icons.pie_chart,
  ),

  /// Categories.
  categories(
    route: AppRoutes.categories,
    labelKey: 'navigation.categories',
    icon: Icons.category_outlined,
    selectedIcon: Icons.category,
  ),

  /// Settings.
  settings(
    route: AppRoutes.settings,
    labelKey: 'navigation.settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const AppDestination({
    required this.route,
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
  });

  /// Path this destination navigates to.
  final String route;

  /// ARB key for the label — never a literal (docs/Conventions.md §5).
  final String labelKey;

  /// Unselected icon.
  final IconData icon;

  /// Selected icon (filled) — docs/Design.md §5.10.
  final IconData selectedIcon;
}
