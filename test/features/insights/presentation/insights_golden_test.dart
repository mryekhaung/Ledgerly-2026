import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/insights/domain/entities/category_breakdown.dart';
import 'package:ledgerly/features/insights/domain/entities/daily_trend_point.dart';
import 'package:ledgerly/features/insights/domain/entities/period_comparison.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/insights/presentation/pages/insights_page.dart';
import 'package:ledgerly/features/insights/presentation/providers/insights_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';
import '../../../support/width_walk.dart';
import '../../categories/domain/fake_category_repository.dart';

/// The insights screen, compact, light + dark (`docs/Design.md` §8).
///
/// The period and the insights stream are both seeded — without the overrides
/// the page resolves against unregistered DI and the golden pins an error
/// banner instead of the charts.
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('insights_golden_test.dart'));

  final period = BudgetPeriod(
    start: LocalDate(2026, 10, 1),
    end: LocalDate(2026, 10, 31),
  );
  final previousPeriod = BudgetPeriod(
    start: LocalDate(2026, 9, 1),
    end: LocalDate(2026, 9, 30),
  );

  final breakdowns = <CategoryBreakdown>[
    CategoryBreakdown(
      category: fakeCategory(
        id: 'cat-food',
        name: 'Food & Dining',
        colorValue: 0xFFE8735A,
        iconKey: 'food',
      ),
      amountMinor: 412000,
      percentage: 0.42,
      currency: CurrencyCode.mmk,
    ),
    CategoryBreakdown(
      category: fakeCategory(
        id: 'cat-transport',
        name: 'Transport',
        colorValue: 0xFF5A8FE8,
        iconKey: 'transport',
      ),
      amountMinor: 236000,
      percentage: 0.24,
      currency: CurrencyCode.mmk,
    ),
    CategoryBreakdown(
      category: fakeCategory(
        id: 'cat-bills',
        name: 'Bills & Utilities',
        colorValue: 0xFF6B5BD2,
        iconKey: 'bills',
      ),
      amountMinor: 333000,
      percentage: 0.34,
      currency: CurrencyCode.mmk,
    ),
  ];

  final trendPoints = <DailyTrendPoint>[
    for (var day = 1; day <= 15; day++)
      DailyTrendPoint(
        date: LocalDate(2026, 10, day),
        incomeMinor: day == 1 ? 1800000 : 0,
        expenseMinor: 40000 + (day * 7300),
        cumulativeNetMinor: 1800000 - (40000 + (day * 7300)) * day,
        currency: CurrencyCode.mmk,
      ),
  ];

  final currentTotal = PeriodTotal(
    period: period,
    incomeMinor: 1800000,
    expenseMinor: 981000,
    currency: CurrencyCode.mmk,
  );

  final insights = PeriodInsights(
    period: period,
    summary: currentTotal,
    comparison: PeriodComparison(
      current: currentTotal,
      previous: PeriodTotal(
        period: previousPeriod,
        incomeMinor: 1750000,
        expenseMinor: 1120000,
        currency: CurrencyCode.mmk,
      ),
    ),
    categoryBreakdowns: breakdowns,
    trendPoints: trendPoints,
  );

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double width = TestWidths.phone,
    double textScale = 1,
  }) => pumpAppHost(
    tester,
    size: Size(width, 900),
    brightness: brightness,
    textScaler: TextScaler.linear(textScale),
    overrides: <Override>[
      currencyProvider.overrideWith((ref) => CurrencyCode.mmk),
      monthStartDayProvider.overrideWith((ref) => 1),
      insightsPeriodProvider.overrideWith(() => _FixedPeriodNotifier(period)),
      insightsDataProvider.overrideWith((ref) => Stream.value(insights)),
    ],
    home: const InsightsPage(),
  );

  widthWalkGroup(pageName: 'InsightsPage', host: host);

  group('Insights screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(InsightsPage),
        matchesGoldenFile('goldens/insights_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(InsightsPage),
        matchesGoldenFile('goldens/insights_dark.png'),
      );
    });
  });
}

/// An [InsightsPeriodNotifier] pinned to one period, so the golden does not
/// depend on the day the suite runs.
class _FixedPeriodNotifier extends InsightsPeriodNotifier {
  _FixedPeriodNotifier(this._initial);

  final BudgetPeriod _initial;

  @override
  BudgetPeriod build() => _initial;
}
