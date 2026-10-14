import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/insights/domain/entities/category_breakdown.dart';
import 'package:ledgerly/features/insights/domain/entities/daily_trend_point.dart';
import 'package:ledgerly/features/insights/domain/entities/period_comparison.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/insights/domain/repositories/insights_repository.dart';
import 'package:ledgerly/features/insights/domain/usecases/watch_period_insights.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';

import '../../categories/domain/fake_category_repository.dart';

class _FakeInsightsRepository implements InsightsRepository {
  _FakeInsightsRepository(this._stream);

  final Stream<PeriodInsights> _stream;

  @override
  Stream<PeriodInsights> watchPeriodInsights({
    required BudgetPeriod period,
    required BudgetPeriod previousPeriod,
    required CurrencyCode currency,
  }) => _stream;
}

void main() {
  final testPeriod = BudgetPeriod(
    start: LocalDate(2026, 10, 1),
    end: LocalDate(2026, 10, 31),
  );
  final prevPeriod = BudgetPeriod(
    start: LocalDate(2026, 9, 1),
    end: LocalDate(2026, 9, 30),
  );

  group('PeriodComparison', () {
    test('computes deltas correctly when previous figures are non-zero', () {
      final current = PeriodTotal(
        period: testPeriod,
        incomeMinor: 500000,
        expenseMinor: 300000,
        currency: CurrencyCode.usd,
      );
      final previous = PeriodTotal(
        period: prevPeriod,
        incomeMinor: 400000,
        expenseMinor: 200000,
        currency: CurrencyCode.usd,
      );

      final comparison = PeriodComparison(current: current, previous: previous);

      expect(comparison.expenseDeltaMinor, equals(100000));
      expect(comparison.incomeDeltaMinor, equals(100000));
      expect(comparison.netDeltaMinor, equals(0));
      expect(comparison.expenseDeltaPercentage, closeTo(50.0, 0.001));
      expect(comparison.incomeDeltaPercentage, closeTo(25.0, 0.001));
    });

    test('returns null delta percentages when previous values are 0', () {
      final current = PeriodTotal(
        period: testPeriod,
        incomeMinor: 200000,
        expenseMinor: 100000,
        currency: CurrencyCode.usd,
      );
      final previous = PeriodTotal.empty(prevPeriod, CurrencyCode.usd);

      final comparison = PeriodComparison(current: current, previous: previous);

      expect(comparison.expenseDeltaPercentage, isNull);
      expect(comparison.incomeDeltaPercentage, isNull);
      expect(comparison.expenseDeltaMinor, equals(100000));
      expect(comparison.incomeDeltaMinor, equals(200000));
    });
  });

  group('CategoryBreakdown', () {
    test('retains properties accurately', () {
      final category = fakeCategory(
        id: 'cat_food',
        name: 'Dining',
        colorValue: 0xFFFF5722,
        iconKey: 'restaurant',
        kind: CategoryKind.expense,
      );

      final breakdown = CategoryBreakdown(
        category: category,
        amountMinor: 25000,
        percentage: 0.25,
        currency: CurrencyCode.usd,
      );

      expect(breakdown.category.id, equals('cat_food'));
      expect(breakdown.amountMinor, equals(25000));
      expect(breakdown.percentage, equals(0.25));
      expect(breakdown.currency, equals(CurrencyCode.usd));
    });
  });

  group('DailyTrendPoint', () {
    test('computes netMinor accurately', () {
      final point = DailyTrendPoint(
        date: LocalDate(2026, 10, 14),
        incomeMinor: 80000,
        expenseMinor: 30000,
        cumulativeNetMinor: 120000,
        currency: CurrencyCode.usd,
      );

      expect(point.netMinor, equals(50000));
      expect(point.cumulativeNetMinor, equals(120000));
    });
  });

  group('PeriodInsights', () {
    test('isEmpty returns true when summary has 0 transactions', () {
      final summary = PeriodTotal.empty(testPeriod, CurrencyCode.usd);
      final comparison = PeriodComparison(
        current: summary,
        previous: PeriodTotal.empty(prevPeriod, CurrencyCode.usd),
      );

      final insights = PeriodInsights(
        period: testPeriod,
        summary: summary,
        comparison: comparison,
        categoryBreakdowns: const <CategoryBreakdown>[],
        trendPoints: const <DailyTrendPoint>[],
      );

      expect(insights.isEmpty, isTrue);
    });

    test('isEmpty returns false when totals are present', () {
      final summary = PeriodTotal(
        period: testPeriod,
        incomeMinor: 10000,
        expenseMinor: 5000,
        currency: CurrencyCode.usd,
      );
      final comparison = PeriodComparison(
        current: summary,
        previous: PeriodTotal.empty(prevPeriod, CurrencyCode.usd),
      );

      final insights = PeriodInsights(
        period: testPeriod,
        summary: summary,
        comparison: comparison,
        categoryBreakdowns: const <CategoryBreakdown>[],
        trendPoints: const <DailyTrendPoint>[],
      );

      expect(insights.isEmpty, isFalse);
    });
  });

  group('WatchPeriodInsights UseCase', () {
    test('delegates to repository.watchPeriodInsights', () async {
      final summary = PeriodTotal.empty(testPeriod, CurrencyCode.usd);
      final comparison = PeriodComparison(
        current: summary,
        previous: PeriodTotal.empty(prevPeriod, CurrencyCode.usd),
      );
      final expected = PeriodInsights(
        period: testPeriod,
        summary: summary,
        comparison: comparison,
        categoryBreakdowns: const <CategoryBreakdown>[],
        trendPoints: const <DailyTrendPoint>[],
      );

      final repo = _FakeInsightsRepository(
        Stream<PeriodInsights>.value(expected),
      );

      final useCase = WatchPeriodInsights(repo);
      final emitted = await useCase(
        period: testPeriod,
        previousPeriod: prevPeriod,
        currency: CurrencyCode.usd,
      ).first;

      expect(emitted, equals(expected));
      expect(emitted.period, equals(testPeriod));
    });
  });
}
