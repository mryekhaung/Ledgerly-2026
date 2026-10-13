import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/insights/domain/repositories/insights_repository.dart';

/// Watches comprehensive insights and analytics for a [BudgetPeriod].
final class WatchPeriodInsights {
  const WatchPeriodInsights(this._repository);

  final InsightsRepository _repository;

  Stream<PeriodInsights> call({
    required BudgetPeriod period,
    required BudgetPeriod previousPeriod,
    required CurrencyCode currency,
  }) =>
      _repository.watchPeriodInsights(
        period: period,
        previousPeriod: previousPeriod,
        currency: currency,
      );
}
