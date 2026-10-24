import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:material_ui/material_ui.dart';

/// Raised period navigator shared by Budgets, Calendar, and Insights.
class AppPeriodSelector extends StatelessWidget {
  /// Creates a period selector.
  const AppPeriodSelector({
    required this.period,
    required this.isPayCycle,
    required this.onPrevious,
    required this.onNext,
    this.onSelectPeriod,
    this.labelOverride,
    this.previousTooltip,
    this.nextTooltip,
    this.selectTooltip,
    super.key,
  });

  /// The period currently displayed.
  final BudgetPeriod period;

  /// Whether to display a date range instead of a calendar month.
  final bool isPayCycle;

  /// Moves to the previous period.
  final VoidCallback? onPrevious;

  /// Moves to the next period.
  final VoidCallback? onNext;

  /// Opens a period picker when the centered label is tapped.
  final VoidCallback? onSelectPeriod;

  /// Replaces the formatted period label while retaining the shared control.
  final String? labelOverride;

  /// Accessible label for the previous-period button.
  final String? previousTooltip;

  /// Accessible label for the next-period button.
  final String? nextTooltip;

  /// Accessible label for the optional period-picker action.
  final String? selectTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final locale = Localizations.localeOf(context);
    final label =
        labelOverride ??
        (isPayCycle
            ? _formatPeriod(period, locale)
            : MaterialLocalizations.of(context).formatMonthYear(
                DateTime(period.start.year, period.start.month),
              ));

    Widget periodLabel = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onSelectPeriod != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          Icon(AppIcons.dropdown, size: 18, color: colors.textSecondary),
        ],
      ],
    );

    if (onSelectPeriod != null) {
      periodLabel = InkWell(
        onTap: onSelectPeriod,
        borderRadius: AppRadius.borderSm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: selectTooltip == null
                ? periodLabel
                : Tooltip(message: selectTooltip!, child: periodLabel),
          ),
        ),
      );
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
            icon: const Icon(AppIcons.chevronLeft, size: 22),
            onPressed: onPrevious,
            tooltip: previousTooltip,
          ),
          Expanded(child: Center(child: periodLabel)),
          IconButton(
            icon: const Icon(AppIcons.chevronRight, size: 22),
            onPressed: onNext,
            tooltip: nextTooltip,
          ),
        ],
      ),
    );
  }

  static String _formatPeriod(BudgetPeriod period, Locale locale) {
    final startDate = period.start.toDateTime();
    final endDate = period.end.toDateTime();
    final localeName = locale.toLanguageTag();
    if (period.start.year != period.end.year) {
      return '${DateFormat.yMMMd(localeName).format(startDate)} – '
          '${DateFormat.yMMMd(localeName).format(endDate)}';
    }
    return '${DateFormat.MMMd(localeName).format(startDate)} – '
        '${DateFormat.MMMd(localeName).format(endDate)}';
  }
}
