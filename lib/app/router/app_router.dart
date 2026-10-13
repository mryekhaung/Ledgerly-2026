import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/router/app_shell.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/presentation/pages/category_list_page.dart';
import 'package:ledgerly/features/profile/presentation/pages/avatar_editor_page.dart';
import 'package:ledgerly/features/profile/presentation/pages/profile_page.dart';
import 'package:ledgerly/features/settings/presentation/pages/month_starts_on_page.dart';
import 'package:ledgerly/features/settings/presentation/pages/settings_page.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/presentation/pages/calendar_page.dart';
import 'package:ledgerly/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:ledgerly/l10n/app_localization.dart';
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
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.calendar,
            name: AppRoutes.calendarName,
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: AppRoutes.insights,
            name: AppRoutes.insightsName,
            builder: (context, state) => const _PlaceholderPage(
              titleKey: 'navigationInsights',
              icon: Icons.pie_chart_outline,
            ),
          ),
          GoRoute(
            path: AppRoutes.categories,
            name: AppRoutes.categoriesName,
            builder: (context, state) => const CategoryListPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: AppRoutes.settingsName,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.settingsMonthStartsOn,
            name: AppRoutes.settingsMonthStartsOnName,
            builder: (context, state) => const MonthStartsOnPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: AppRoutes.profileName,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // Add / edit transaction are top-level (outside the shell) so they can be
      // presented as a full-screen page on compact and a centered modal page on
      // medium+ (docs/Platform.md §5).
      GoRoute(
        path: AppRoutes.transactionNew,
        name: AppRoutes.transactionNewName,
        builder: (context, state) =>
            TransactionFormPage(initialDate: _dateFromQuery(state)),
        routes: <RouteBase>[
          // Nested so the edit path inherits the new-transaction segment and the
          // two can never be confused: `/transactions/new` vs
          // `/transactions/<id>/edit`.
          GoRoute(
            path: AppRoutes.transactionEditRelative,
            name: AppRoutes.transactionEditName,
            builder: (context, state) =>
                _TransactionEditLoader(id: state.pathParameters['id']!),
          ),
        ],
      ),

      // Avatar editor is a full-screen route OUTSIDE the shell (docs/Avatar.md §2
      // step 0): no bottom navigation, so the pinned Save bar owns the bottom
      // edge and the preview never competes with a tab bar. Reached by deep link
      // `/profile/avatar` or by `pushNamed` from the Profile page; popping
      // returns to the profile, which stays in the shell.
      GoRoute(
        path: '/profile/avatar',
        name: AppRoutes.avatarEditorName,
        builder: (context, state) => const AvatarEditorPage(),
      ),
    ],
  );
}

/// Reads the optional `?date=yyyyMMdd` a deep link or the calendar may supply.
///
/// Parsed through `LocalDate.fromPacked` so a malformed value is dropped rather
/// than crashing the page — the form falls back to today.
LocalDate? _dateFromQuery(GoRouterState state) {
  final raw = state.uri.queryParameters['date'];
  if (raw == null) return null;
  return LocalDate.fromPacked(int.tryParse(raw) ?? 0);
}

/// Loads the transaction being edited, then renders the form.
///
/// The id arrives from the route, so the page cannot be built until the row is
/// resolved. A missing row renders the not-found state rather than an empty form
/// that would silently create a second transaction on save.
class _TransactionEditLoader extends ConsumerWidget {
  const _TransactionEditLoader({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    // `getTransactionProvider` is a factory, so reading it here builds a fresh
    // use case per loader rather than sharing mutable state across routes.
    final future = ref.watch(getTransactionProvider)((id: id));

    return FutureBuilder<Result<Transaction>>(
      future: future,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null) return const _EditLoadingScaffold();

        return result.fold(
          onSuccess: (transaction) =>
              TransactionFormPage(existing: transaction),
          onErr: (failure) => Scaffold(
            appBar: AppBar(),
            body: StatePlaceholder(
              icon: Icons.search_off,
              title: strings('stateEmptyTitle'),
              body: strings(
                AppLocalization.failureKeyFor(failure.runtimeType.toString()),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A bare app bar while the row loads, so the route transition has a frame to
/// land on instead of a blank screen.
class _EditLoadingScaffold extends StatelessWidget {
  const _EditLoadingScaffold();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: SafeArea(child: LoadingPlaceholder()));
}

/// Not-yet-built destination. States plainly that the feature is missing — no
/// Lorem, no fake data (`docs/Agent.md` §8) — through the same
/// [StatePlaceholder] every other empty state uses, so it matches the design
/// system instead of being a bespoke one-off.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.titleKey, required this.icon});

  final String titleKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings(titleKey))),
      body: StatePlaceholder(
        icon: icon,
        title: strings(titleKey),
        body: strings('stateComingSoon'),
      ),
    );
  }
}
