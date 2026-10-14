import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/insights/data/datasources/insights_local_datasource.dart';
import 'package:ledgerly/features/insights/data/repositories/insights_repository_impl.dart';
import 'package:ledgerly/features/insights/domain/entities/category_breakdown.dart';
import 'package:ledgerly/features/insights/domain/entities/daily_trend_point.dart';
import 'package:ledgerly/features/insights/domain/entities/period_comparison.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';

class _FakeLocalDataSource implements InsightsLocalDataSource {
  _FakeLocalDataSource(this._stream);

  final Stream<PeriodInsights> _stream;

  @override
  Stream<PeriodInsights> watchPeriodInsights({
    required BudgetPeriod period,
    required BudgetPeriod previousPeriod,
    required CurrencyCode currency,
  }) => _stream;
}

void main() {
  test('InsightsRepositoryImpl delegates to InsightsLocalDataSource', () async {
    final period = BudgetPeriod(
      start: LocalDate(2026, 10, 1),
      end: LocalDate(2026, 10, 31),
    );
    final previousPeriod = BudgetPeriod(
      start: LocalDate(2026, 9, 1),
      end: LocalDate(2026, 9, 30),
    );

    final expectedInsights = PeriodInsights(
      period: period,
      summary: PeriodTotal.empty(period, CurrencyCode.usd),
      comparison: PeriodComparison(
        current: PeriodTotal.empty(period, CurrencyCode.usd),
        previous: PeriodTotal.empty(previousPeriod, CurrencyCode.usd),
      ),
      categoryBreakdowns: const <CategoryBreakdown>[],
      trendPoints: const <DailyTrendPoint>[],
    );

    final dataSource = _FakeLocalDataSource(
      Stream<PeriodInsights>.value(expectedInsights),
    );
    final repository = InsightsRepositoryImpl(dataSource);

    final result = await repository
        .watchPeriodInsights(
          period: period,
          previousPeriod: previousPeriod,
          currency: CurrencyCode.usd,
        )
        .first;

    expect(result, equals(expectedInsights));
  });
}
