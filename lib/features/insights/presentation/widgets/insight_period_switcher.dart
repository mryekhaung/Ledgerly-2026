import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_period_selector.dart';
import 'package:material_ui/material_ui.dart';

/// Top bar switcher for navigating budget periods on the Insights page.
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
    if (isPayCycle) {
      return AppPeriodSelector(
        period: period,
        isPayCycle: true,
        onPrevious: onPrevious,
        onNext: onNext,
        previousTooltip: strings('insightsPreviousPeriod'),
        nextTooltip: strings('insightsNextPeriod'),
      );
    }

    final theme = Theme.of(context);
    final label = MaterialLocalizations.of(context)
        .formatMonthYear(DateTime(period.start.year, period.start.month));

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(AppIcons.chevronLeft),
          tooltip: strings('insightsPreviousPeriod'),
        ),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44.0),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(AppIcons.chevronRight),
          tooltip: strings('insightsNextPeriod'),
        ),
      ],
    );
  }
}
