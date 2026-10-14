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

  /// Transactions list and search (Phase 2).
  static const String transactions = '/transactions';
  static const String transactionsName = 'transactions';

  /// Add / edit transaction (Phase 1). Dedicated page, never a dialog.
  static const String transactionNew = '/transactions/new';
  static const String transactionNewName = 'transactionNew';

  /// Relative to [transactionNew], so the router nests it and the two paths can
  /// never collide.
  static const String transactionEditRelative = ':id/edit';
  static const String transactionEditName = 'transactionEdit';

  /// Sub-route of the settings branch (Phase 1).
  static const String settingsCurrency = '/settings/currency';
  static const String settingsCurrencyName = 'settingsCurrency';

  /// Month starts on picker (Phase 1, docs/Design.md §6.6).
  static const String settingsMonthStartsOn = '/settings/month-starts-on';
  static const String settingsMonthStartsOnName = 'settingsMonthStartsOn';

  /// Profile (Phase 1). Reached from the settings list and the shell avatar —
  /// it is a secondary destination, not a fifth tab.
  static const String profile = '/profile';
  static const String profileName = 'profile';

  /// Avatar editor — a top-level, full-screen route OUTSIDE the shell
  /// (docs/Avatar.md §2 step 0): no bottom navigation, so the Save bar owns the
  /// bottom edge. Reached by deep link `/profile/avatar` or by `pushNamed` from
  /// the Profile page; popping returns to the profile (which stays in the shell).
  static const String avatarEditorName = 'avatarEditor';

  /// Welcome and onboarding page (Phase 2).
  static const String welcome = '/welcome';
  static const String welcomeName = 'welcome';

  /// Sign-in / registration page (Phase 2).
  static const String signIn = '/sign-in';
  static const String signInName = 'signIn';

  /// Account management page (Phase 2).
  static const String account = '/settings/account';
  static const String accountName = 'account';
}
