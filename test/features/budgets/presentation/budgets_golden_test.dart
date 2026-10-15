import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/presentation/pages/budgets_page.dart';
import 'package:ledgerly/features/budgets/presentation/providers/budget_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';

/// The budgets screen, compact, light + dark (`docs/Design.md` §8).
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('budgets_golden_test.dart'));

  final period = BudgetPeriod(
    start: LocalDate(2026, 10, 1),
    end: LocalDate(2026, 10, 31),
  );

  // MMK has no minor unit, so these are whole kyats: a 1,500,000 Ks period
  // budget (roughly USD 700) with a 400,000 Ks food budget. Deliberately
  // realistic — 7-digit amounts are what the layout actually has to hold.
  const totalBudget = Budget(
    id: 'b-total',
    categoryId: null,
    periodId: '2026-10',
    amountMinor: 1500000,
    currency: CurrencyCode.mmk,
    alertThreshold: 0.8,
    sortOrder: 0,
    isArchived: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  const catBudget = Budget(
    id: 'b-cat-1',
    categoryId: 'cat-food',
    periodId: '2026-10',
    amountMinor: 400000,
    currency: CurrencyCode.mmk,
    alertThreshold: 0.8,
    sortOrder: 1,
    isArchived: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  final totalProgress = BudgetProgress(
    budget: totalBudget,
    spentMinor: 900000,
    period: period,
  );

  final catProgress = BudgetProgress(
    budget: catBudget,
    spentMinor: 320000,
    period: period,
    categoryName: 'Food & Dining',
    categoryIcon: 'food',
    categoryColor: 0xFF22C55E,
  );

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) => pumpAppHost(
    tester,
    size: const Size(TestWidths.phone, 900),
    brightness: brightness,
    overrides: <Override>[
      budgetProgressStreamProvider.overrideWith(
        (ref) => Stream.value([totalProgress, catProgress]),
      ),
      currencyProvider.overrideWith((ref) => CurrencyCode.mmk),
    ],
    home: const BudgetsPage(),
  );

  group('Budgets screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BudgetsPage),
        matchesGoldenFile('goldens/budgets_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BudgetsPage),
        matchesGoldenFile('goldens/budgets_dark.png'),
      );
    });
  });
}
