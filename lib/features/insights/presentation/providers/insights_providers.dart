import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/insights/domain/usecases/watch_period_insights.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';

/// Service locator bridge for [WatchPeriodInsights].
final watchPeriodInsightsProvider = Provider<WatchPeriodInsights>(
  (_) => getIt<WatchPeriodInsights>(),
);

/// The active budget period browsed on the Insights page.
final insightsPeriodProvider =
    NotifierProvider<InsightsPeriodNotifier, BudgetPeriod>(
      InsightsPeriodNotifier.new,
    );

class InsightsPeriodNotifier extends Notifier<BudgetPeriod> {
  @override
  BudgetPeriod build() {
    final calculator = ref.watch(periodCalculatorProvider);
    final today = LocalDate.fromDateTime(DateTime.now());
    return calculator.containing(today);
  }

  void previous() {
    final calculator = ref.read(periodCalculatorProvider);
    state = calculator.previous(state);
  }

  void next() {
    final calculator = ref.read(periodCalculatorProvider);
    state = calculator.next(state);
  }

  void jumpTo(BudgetPeriod period) {
    state = period;
  }
}

/// Reactive stream of insights for the selected period.
final insightsDataProvider = StreamProvider.autoDispose<PeriodInsights>((ref) {
  final period = ref.watch(insightsPeriodProvider);
  final calculator = ref.watch(periodCalculatorProvider);
  final previousPeriod = calculator.previous(period);
  final currency = ref.watch(currencyProvider);
  final useCase = ref.watch(watchPeriodInsightsProvider);

  return useCase(
    period: period,
    previousPeriod: previousPeriod,
    currency: currency,
  );
});
