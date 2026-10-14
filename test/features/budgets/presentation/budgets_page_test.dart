import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/presentation/pages/budget_form_page.dart';
import 'package:ledgerly/features/budgets/presentation/pages/budgets_page.dart';
import 'package:ledgerly/features/budgets/presentation/providers/budget_providers.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_category_row.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_period_selector.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_summary_card.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

void main() {
  final period = BudgetPeriod(
    start: LocalDate(2026, 10, 1),
    end: LocalDate(2026, 10, 31),
  );

  const totalBudget = Budget(
    id: 'b-total',
    categoryId: null,
    periodId: '2026-10',
    amountMinor: 100000000, // 1,000,000 MMK
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
    amountMinor: 20000000, // 200,000 MMK
    currency: CurrencyCode.mmk,
    alertThreshold: 0.8,
    sortOrder: 1,
    isArchived: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  final totalProgress = BudgetProgress(
    budget: totalBudget,
    spentMinor: 45000000,
    period: period,
  );

  final catProgress = BudgetProgress(
    budget: catBudget,
    spentMinor: 18000000,
    period: period,
    categoryName: 'Food & Dining',
    categoryIcon: 'restaurant',
    categoryColor: 0xFF22C55E,
  );

  const testCategory = Category(
    id: 'cat-food',
    name: 'Food & Dining',
    iconKey: 'restaurant',
    colorValue: 0xFF22C55E,
    kind: CategoryKind.expense,
    sortOrder: 0,
    isDefault: true,
    isArchived: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  group('BudgetsPage', () {
    testWidgets('renders empty state when there are no budgets', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          budgetProgressStreamProvider.overrideWith(
            (ref) => Stream.value(const <BudgetProgress>[]),
          ),
          currencyProvider.overrideWith((ref) => CurrencyCode.mmk),
        ],
        home: const BudgetsPage(),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BudgetPeriodSelector), findsOneWidget);
      expect(find.byType(BudgetSummaryCard), findsOneWidget);
      expect(find.text('No budgets yet'), findsOneWidget);
    });

    testWidgets('renders total budget summary and category breakdown', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          budgetProgressStreamProvider.overrideWith(
            (ref) => Stream.value([totalProgress, catProgress]),
          ),
          currencyProvider.overrideWith((ref) => CurrencyCode.mmk),
        ],
        home: const BudgetsPage(),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BudgetPeriodSelector), findsOneWidget);
      expect(find.byType(BudgetSummaryCard), findsOneWidget);
      expect(find.byType(BudgetCategoryRow), findsOneWidget);
      expect(find.text('Food & Dining'), findsOneWidget);
      // Status is Near Limit (180,000 / 200,000 = 90% >= 80% threshold)
      expect(find.text('Near Limit'), findsWidgets);
    });
  });

  group('BudgetFormPage', () {
    testWidgets('renders form fields with default values', (tester) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          pickableCategoriesProvider(CategoryKind.expense)
              .overrideWith((ref) => Stream.value([testCategory])),
          currencyProvider.overrideWith((ref) => CurrencyCode.mmk),
        ],
        home: const BudgetFormPage(),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Budget'), findsOneWidget);
      expect(find.text('Total Budget'), findsNWidgets(2));
      expect(find.text('Category Budget'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('toggles to Category Budget and allows selecting category', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          pickableCategoriesProvider(CategoryKind.expense)
              .overrideWith((ref) => Stream.value([testCategory])),
          currencyProvider.overrideWith((ref) => CurrencyCode.mmk),
        ],
        home: const BudgetFormPage(),
      );

      await tester.pumpAndSettle();

      // Tap "Category Budget" segment
      await tester.tap(find.text('Category Budget'));
      await tester.pumpAndSettle();

      // Dropdown appears with category
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });
  });
}
