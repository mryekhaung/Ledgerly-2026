import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/presentation/pages/goal_form_page.dart';
import 'package:ledgerly/features/goals/presentation/pages/goals_list_page.dart';
import 'package:ledgerly/features/goals/presentation/providers/goals_providers.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_card.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

void main() {
  final activeGoal = SavingsGoal(
    id: 'goal-1',
    name: 'Vacation to Japan',
    targetAmount: const Money.minor(3000000, CurrencyCode.mmk),
    currentAmount: const Money.minor(1000000, CurrencyCode.mmk),
    targetDate: LocalDate(2026, 12, 1),
    iconKey: 'flight',
    colorValue: 0xFF1976D2,
    notes: 'Winter holiday in Tokyo',
    isArchived: false,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  final completedGoal = SavingsGoal(
    id: 'goal-2',
    name: 'New Laptop',
    targetAmount: const Money.minor(2000000, CurrencyCode.mmk),
    currentAmount: const Money.minor(2000000, CurrencyCode.mmk),
    targetDate: LocalDate(2026, 11, 1),
    iconKey: 'laptop',
    colorValue: 0xFF2E7D32,
    notes: 'MacBook Pro',
    isArchived: false,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  final archivedGoal = SavingsGoal(
    id: 'goal-3',
    name: 'Cancelled Trip',
    targetAmount: const Money.minor(500000, CurrencyCode.mmk),
    currentAmount: const Money.minor(100000, CurrencyCode.mmk),
    iconKey: 'flight',
    colorValue: 0xFF757575,
    notes: 'Postponed indefinitely',
    isArchived: true,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  group('GoalsListPage', () {
    testWidgets('renders empty state when there are no active goals', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: [
          activeGoalsProvider.overrideWithValue(
            const AsyncData(<SavingsGoal>[]),
          ),
          completedGoalsProvider.overrideWithValue(
            const AsyncData(<SavingsGoal>[]),
          ),
          archivedGoalsProvider.overrideWithValue(
            const AsyncData(<SavingsGoal>[]),
          ),
        ],
        home: const GoalsListPage(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('No Savings Goals Yet'), findsOneWidget);
    });

    testWidgets('renders goal cards on active tab when active goals exist', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: [
          activeGoalsProvider.overrideWithValue(
            AsyncData(<SavingsGoal>[activeGoal]),
          ),
          completedGoalsProvider.overrideWithValue(
            const AsyncData(<SavingsGoal>[]),
          ),
          archivedGoalsProvider.overrideWithValue(
            const AsyncData(<SavingsGoal>[]),
          ),
        ],
        home: const GoalsListPage(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GoalCard), findsOneWidget);
      expect(find.text('Vacation to Japan'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders completed goals on Completed tab', (tester) async {
      await pumpAppHost(
        tester,
        overrides: [
          activeGoalsProvider.overrideWithValue(
            const AsyncData(<SavingsGoal>[]),
          ),
          completedGoalsProvider.overrideWithValue(
            AsyncData(<SavingsGoal>[completedGoal]),
          ),
          archivedGoalsProvider.overrideWithValue(
            const AsyncData(<SavingsGoal>[]),
          ),
        ],
        home: const GoalsListPage(),
      );
      await tester.pumpAndSettle();

      // Tap Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.byType(GoalCard), findsOneWidget);
      expect(find.text('New Laptop'), findsOneWidget);
    });

    testWidgets('renders archived goals on Archived tab', (tester) async {
      await pumpAppHost(
        tester,
        overrides: [
          activeGoalsProvider.overrideWithValue(
            const AsyncData(<SavingsGoal>[]),
          ),
          completedGoalsProvider.overrideWithValue(
            const AsyncData(<SavingsGoal>[]),
          ),
          archivedGoalsProvider.overrideWithValue(
            AsyncData(<SavingsGoal>[archivedGoal]),
          ),
        ],
        home: const GoalsListPage(),
      );
      await tester.pumpAndSettle();

      // Tap Archived tab
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      expect(find.byType(GoalCard), findsOneWidget);
      expect(find.text('Cancelled Trip'), findsOneWidget);
    });
  });

  group('GoalFormPage', () {
    testWidgets('renders create goal form correctly', (tester) async {
      await pumpAppHost(
        tester,
        overrides: [
          currencyProvider.overrideWithValue(CurrencyCode.mmk),
          accountsStreamProvider.overrideWith(
            (ref) => Stream.value(const <Account>[]),
          ),
        ],
        home: const GoalFormPage(),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Goal'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4));
    });
  });
}
