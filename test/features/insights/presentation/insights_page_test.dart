import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/insights/domain/entities/category_breakdown.dart';
import 'package:ledgerly/features/insights/domain/entities/daily_trend_point.dart';
import 'package:ledgerly/features/insights/domain/entities/period_comparison.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/insights/presentation/pages/insights_page.dart';
import 'package:ledgerly/features/insights/presentation/providers/insights_providers.dart';
import 'package:ledgerly/features/insights/presentation/widgets/cash_flow_line_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/donut_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/income_expense_bar_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/insight_period_switcher.dart';
import 'package:ledgerly/features/insights/presentation/widgets/insight_summary_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/top_categories_card.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../categories/domain/fake_category_repository.dart';

void main() {
  final testPeriod = BudgetPeriod(
    start: LocalDate(2026, 10, 1),
    end: LocalDate(2026, 10, 31),
  );
  final prevPeriod = BudgetPeriod(
    start: LocalDate(2026, 9, 1),
    end: LocalDate(2026, 9, 30),
  );

  final sampleBreakdown = CategoryBreakdown(
    category: fakeCategory(
      id: 'cat_groceries',
      name: 'Groceries',
      colorValue: 0xFF4CAF50,
      iconKey: 'restaurant',
      kind: CategoryKind.expense,
    ),
    amountMinor: 25000,
    percentage: 0.5,
    currency: CurrencyCode.usd,
  );

  final sampleTrend = DailyTrendPoint(
    date: LocalDate(2026, 10, 15),
    incomeMinor: 100000,
    expenseMinor: 50000,
    cumulativeNetMinor: 50000,
    currency: CurrencyCode.usd,
  );

  final populatedInsights = PeriodInsights(
    period: testPeriod,
    summary: PeriodTotal(
      period: testPeriod,
      incomeMinor: 100000,
      expenseMinor: 50000,
      currency: CurrencyCode.usd,
    ),
    comparison: PeriodComparison(
      current: PeriodTotal(
        period: testPeriod,
        incomeMinor: 100000,
        expenseMinor: 50000,
        currency: CurrencyCode.usd,
      ),
      previous: PeriodTotal(
        period: prevPeriod,
        incomeMinor: 80000,
        expenseMinor: 40000,
        currency: CurrencyCode.usd,
      ),
    ),
    categoryBreakdowns: <CategoryBreakdown>[sampleBreakdown],
    trendPoints: <DailyTrendPoint>[sampleTrend],
  );

  final emptyInsights = PeriodInsights(
    period: testPeriod,
    summary: PeriodTotal.empty(testPeriod, CurrencyCode.usd),
    comparison: PeriodComparison(
      current: PeriodTotal.empty(testPeriod, CurrencyCode.usd),
      previous: PeriodTotal.empty(prevPeriod, CurrencyCode.usd),
    ),
    categoryBreakdowns: const <CategoryBreakdown>[],
    trendPoints: const <DailyTrendPoint>[],
  );

  Future<void> hostInsights(
    WidgetTester tester, {
    required Stream<PeriodInsights> stream,
    Size size = const Size(400, 800),
  }) async {
    await pumpAppHost(
      tester,
      size: size,
      overrides: <Override>[
        currencyProvider.overrideWith((ref) => CurrencyCode.usd),
        monthStartDayProvider.overrideWith((ref) => 1),
        insightsPeriodProvider.overrideWith(
          () => _FixedPeriodNotifier(testPeriod),
        ),
        insightsDataProvider.overrideWith((ref) => stream),
      ],
      home: const InsightsPage(),
    );
  }

  group('InsightsPage states', () {
    testWidgets('shows loading placeholder initially', (tester) async {
      await hostInsights(tester, stream: const Stream<PeriodInsights>.empty());
      await tester.pump();

      expect(find.byType(LoadingPlaceholder), findsOneWidget);
    });

    testWidgets('shows empty state placeholder when no transactions exist', (
      tester,
    ) async {
      await hostInsights(
        tester,
        stream: Stream<PeriodInsights>.value(emptyInsights),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatePlaceholder), findsOneWidget);
      expect(find.text('No transactions yet'), findsOneWidget);
    });

    testWidgets('shows full insights dashboard when populated', (tester) async {
      await hostInsights(
        tester,
        stream: Stream<PeriodInsights>.value(populatedInsights),
        size: const Size(500, 1600),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InsightPeriodSwitcher), findsOneWidget);
      expect(find.byType(InsightSummaryCard), findsOneWidget);
      expect(find.byType(DonutChartCard), findsOneWidget);
      expect(find.byType(IncomeExpenseBarChartCard), findsOneWidget);
      expect(find.byType(CashFlowLineChartCard), findsOneWidget);
      expect(find.byType(TopCategoriesCard), findsOneWidget);
      expect(find.text('Groceries'), findsWidgets);
    });
  });

  group('InsightsPage responsive layouts', () {
    testWidgets('compact phone layout (< 600px)', (tester) async {
      await hostInsights(
        tester,
        stream: Stream<PeriodInsights>.value(populatedInsights),
        size: const Size(360, 1000),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InsightSummaryCard), findsOneWidget);
      expect(find.byType(DonutChartCard), findsOneWidget);
    });

    testWidgets('medium tablet layout (600-1199px)', (tester) async {
      await hostInsights(
        tester,
        stream: Stream<PeriodInsights>.value(populatedInsights),
        size: const Size(800, 1000),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InsightSummaryCard), findsOneWidget);
      expect(find.byType(IncomeExpenseBarChartCard), findsOneWidget);
    });

    testWidgets('large desktop layout (>= 1200px)', (tester) async {
      await hostInsights(
        tester,
        stream: Stream<PeriodInsights>.value(populatedInsights),
        size: const Size(1280, 1000),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InsightSummaryCard), findsOneWidget);
      expect(find.byType(CashFlowLineChartCard), findsOneWidget);
    });
  });
}

class _FixedPeriodNotifier extends InsightsPeriodNotifier {
  _FixedPeriodNotifier(this._initial);

  final BudgetPeriod _initial;

  @override
  BudgetPeriod build() => _initial;
}
