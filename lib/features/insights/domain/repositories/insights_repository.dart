import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';

/// Contract for reactive analytics queries by budget period.
///
/// Follows Clean Architecture: pure Dart interface without platform or storage dependencies.
abstract interface class InsightsRepository {
  /// Emits updated [PeriodInsights] whenever transactions or categories change.
  Stream<PeriodInsights> watchPeriodInsights({
    required BudgetPeriod period,
    required BudgetPeriod previousPeriod,
    required CurrencyCode currency,
  });
}
