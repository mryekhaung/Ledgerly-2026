import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/period/budget_period.dart';
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final locale = Localizations.localeOf(context);

    final String label;
    if (isPayCycle) {
      final startFmt = DateFormat.MMMd(locale.toString()).format(
        DateTime(period.start.year, period.start.month, period.start.day),
      );
      final endFmt = DateFormat.MMMd(locale.toString())
          .format(DateTime(period.end.year, period.end.month, period.end.day));
      label = '$startFmt – $endFmt';
    } else {
      label = MaterialLocalizations.of(context)
          .formatMonthYear(DateTime(period.start.year, period.start.month));
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: onPrevious,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            onPressed: onNext,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
