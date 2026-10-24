import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/widgets/app_period_selector.dart';
import 'package:material_ui/material_ui.dart';

/// Top bar switcher for navigating budget periods on the Budgets page.
class BudgetPeriodSelector extends StatelessWidget {
  const BudgetPeriodSelector({
    required this.period,
    required this.onPrevious,
    required this.onNext,
    this.isPayCycle = false,
    super.key,
  });

  final BudgetPeriod period;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isPayCycle;

  @override
  Widget build(BuildContext context) => AppPeriodSelector(
    period: period,
    isPayCycle: isPayCycle,
    onPrevious: onPrevious,
    onNext: onNext,
  );
}
