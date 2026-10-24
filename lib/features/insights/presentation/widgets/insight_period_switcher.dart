import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_period_selector.dart';
import 'package:material_ui/material_ui.dart';

/// Period navigation on the Insights page.
class InsightPeriodSwitcher extends StatelessWidget {
  const InsightPeriodSwitcher({
    required this.period,
    required this.isPayCycle,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final BudgetPeriod period;
  final bool isPayCycle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppPeriodSelector(
      period: period,
      isPayCycle: isPayCycle,
      onPrevious: onPrevious,
      onNext: onNext,
      previousTooltip: strings('insightsPreviousPeriod'),
      nextTooltip: strings('insightsNextPeriod'),
    );
  }
}
