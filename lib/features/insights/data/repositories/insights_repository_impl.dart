import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/features/insights/data/datasources/insights_local_datasource.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/insights/domain/repositories/insights_repository.dart';

/// Implementation of [InsightsRepository] delegating to [InsightsLocalDataSource].
final class InsightsRepositoryImpl implements InsightsRepository {
  const InsightsRepositoryImpl(this._localDataSource);

  final InsightsLocalDataSource _localDataSource;

  @override
  Stream<PeriodInsights> watchPeriodInsights({
    required BudgetPeriod period,
    required BudgetPeriod previousPeriod,
    required CurrencyCode currency,
  }) => _localDataSource.watchPeriodInsights(
    period: period,
    previousPeriod: previousPeriod,
    currency: currency,
  );
}
