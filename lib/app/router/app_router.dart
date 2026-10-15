import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/router/app_shell.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/accounts/presentation/pages/account_form_page.dart';
import 'package:ledgerly/features/accounts/presentation/pages/accounts_page.dart';
import 'package:ledgerly/features/accounts/presentation/pages/transfer_page.dart';
import 'package:ledgerly/features/auth/presentation/pages/account_page.dart';
import 'package:ledgerly/features/auth/presentation/pages/sign_in_page.dart';
import 'package:ledgerly/features/auth/presentation/pages/welcome_page.dart';
import 'package:ledgerly/features/budgets/presentation/pages/budget_form_page.dart';
import 'package:ledgerly/features/budgets/presentation/pages/budgets_page.dart';
import 'package:ledgerly/features/categories/presentation/pages/category_list_page.dart';
import 'package:ledgerly/features/data_transfer/presentation/pages/data_transfer_page.dart';
import 'package:ledgerly/features/goals/presentation/pages/goal_form_page.dart';
import 'package:ledgerly/features/goals/presentation/pages/goals_list_page.dart';
import 'package:ledgerly/features/insights/presentation/pages/insights_page.dart';
import 'package:ledgerly/features/profile/presentation/pages/avatar_editor_page.dart';
import 'package:ledgerly/features/profile/presentation/pages/profile_page.dart';
import 'package:ledgerly/features/recurring/presentation/pages/recurring_form_page.dart';
import 'package:ledgerly/features/recurring/presentation/pages/recurring_list_page.dart';
import 'package:ledgerly/features/settings/presentation/pages/month_starts_on_page.dart';
import 'package:ledgerly/features/settings/presentation/pages/settings_page.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/presentation/pages/calendar_page.dart';
import 'package:ledgerly/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:ledgerly/features/transactions/presentation/pages/transactions_list_page.dart';
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
            builder: (context, state) => const InsightsPage(),
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
        ],
      ),

      // Pushed sub-screens (outside the shell) so they hide the bottom
      // navigation bar, have full vertical canvas, and support seamless
      // predictive back gestures.
      GoRoute(
        path: AppRoutes.transactions,
        name: AppRoutes.transactionsName,
        builder: (context, state) => const TransactionsListPage(),
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
      GoRoute(
        path: AppRoutes.account,
        name: AppRoutes.accountName,
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: AppRoutes.dataTransfer,
        name: AppRoutes.dataTransferName,
        builder: (context, state) => const DataTransferPage(),
      ),
      GoRoute(
        path: AppRoutes.accounts,
        name: AppRoutes.accountsName,
        builder: (context, state) => const AccountsPage(),
      ),
      GoRoute(
        path: AppRoutes.budgets,
        name: AppRoutes.budgetsName,
        builder: (context, state) => const BudgetsPage(),
      ),
      GoRoute(
        path: AppRoutes.recurring,
        name: AppRoutes.recurringName,
        builder: (context, state) => const RecurringListPage(),
      ),

      // Onboarding / Welcome and Sign-In are top-level routes OUTSIDE the shell
      // (no bottom navigation bar).
      GoRoute(
        path: AppRoutes.welcome,
        name: AppRoutes.welcomeName,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: AppRoutes.signInName,
        builder: (context, state) => const SignInPage(),
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

      // Account forms and transfers (Phase 3).
      GoRoute(
        path: AppRoutes.accountNew,
        name: AppRoutes.accountNewName,
        builder: (context, state) => const AccountFormPage(),
      ),
      GoRoute(
        path: AppRoutes.accountEdit,
        name: AppRoutes.accountEditName,
        builder: (context, state) =>
            AccountFormPage(accountId: state.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.accountTransfer,
        name: AppRoutes.accountTransferName,
        builder: (context, state) => TransferPage(
          initialFromId: state.uri.queryParameters['from'],
          initialToId: state.uri.queryParameters['to'],
        ),
      ),

      // Budget forms (Phase 3).
      GoRoute(
        path: AppRoutes.budgetNew,
        name: AppRoutes.budgetNewName,
        builder: (context, state) =>
            BudgetFormPage(initialType: state.uri.queryParameters['type']),
      ),
      GoRoute(
        path: AppRoutes.budgetEdit,
        name: AppRoutes.budgetEditName,
        builder: (context, state) =>
            BudgetFormPage(budgetId: state.pathParameters['id']),
      ),

      // Recurring forms (Phase 3).
      GoRoute(
        path: AppRoutes.recurringNew,
        name: AppRoutes.recurringNewName,
        builder: (context, state) => const RecurringFormPage(),
      ),
      GoRoute(
        path: AppRoutes.recurringEdit,
        name: AppRoutes.recurringEditName,
        builder: (context, state) =>
            RecurringFormPage(recurringId: state.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.goals,
        name: AppRoutes.goalsName,
        builder: (context, state) => const GoalsListPage(),
      ),
      GoRoute(
        path: AppRoutes.goalsNew,
        name: AppRoutes.goalsNewName,
        builder: (context, state) => const GoalFormPage(),
      ),
      GoRoute(
        path: AppRoutes.goalsEdit,
        name: AppRoutes.goalsEditName,
        builder: (context, state) =>
            GoalFormPage(goalId: state.pathParameters['id']),
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
              icon: AppIcons.searchOff,
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
