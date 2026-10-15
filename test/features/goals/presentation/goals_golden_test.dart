import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/presentation/pages/goals_list_page.dart';
import 'package:ledgerly/features/goals/presentation/providers/goals_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';

/// The goals list screen, compact, light + dark (`docs/Design.md` §8).
///
/// The providers are seeded with real goals rather than left to resolve against
/// unregistered DI: without them the page paints its error banner, so the
/// golden would pin the failure state instead of the screen.
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('goals_golden_test.dart'));

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

  final secondGoal = SavingsGoal(
    id: 'goal-2',
    name: 'Emergency Fund',
    targetAmount: const Money.minor(5000000, CurrencyCode.mmk),
    currentAmount: const Money.minor(1250000, CurrencyCode.mmk),
    targetDate: LocalDate(2027, 3, 1),
    iconKey: 'savings',
    colorValue: 0xFF2E7D32,
    notes: 'Six months of expenses',
    isArchived: false,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) => pumpAppHost(
    tester,
    size: const Size(TestWidths.phone, 900),
    brightness: brightness,
    overrides: <Override>[
      activeGoalsProvider.overrideWithValue(
        AsyncData(<SavingsGoal>[activeGoal, secondGoal]),
      ),
      completedGoalsProvider.overrideWithValue(
        const AsyncData(<SavingsGoal>[]),
      ),
      archivedGoalsProvider.overrideWithValue(const AsyncData(<SavingsGoal>[])),
    ],
    home: const GoalsListPage(),
  );

  group('Goals screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GoalsListPage),
        matchesGoldenFile('goldens/goals_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GoalsListPage),
        matchesGoldenFile('goldens/goals_dark.png'),
      );
    });
  });
}
