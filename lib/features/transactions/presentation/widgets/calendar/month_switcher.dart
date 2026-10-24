import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_period_selector.dart';
import 'package:material_ui/material_ui.dart';

/// Calendar period navigation using the shared raised selector.
class MonthSwitcher extends StatelessWidget {
  /// Creates a [MonthSwitcher].
  const MonthSwitcher({
    required this.period,
    required this.isPayCycle,
    required this.onPrevious,
    required this.onNext,
    required this.onPickMonth,
    super.key,
  });

  /// The currently visible budget period.
  final BudgetPeriod period;

  /// Whether the period is a pay-cycle range rather than a calendar month.
  final bool isPayCycle;

  /// Move one period back.
  final VoidCallback onPrevious;

  /// Move one period forward.
  final VoidCallback onNext;

  /// Open the month/year picker.
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppPeriodSelector(
      period: period,
      isPayCycle: isPayCycle,
      onPrevious: onPrevious,
      onNext: onNext,
      onSelectPeriod: onPickMonth,
      previousTooltip: strings('calendarPreviousMonth'),
      nextTooltip: strings('calendarNextMonth'),
      selectTooltip: strings('calendarPickMonth'),
    );
  }
}
