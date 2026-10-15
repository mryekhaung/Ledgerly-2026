import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// The `< March 2026 >` header.
///
/// The title in the middle is tappable and opens the month/year picker — the
/// only way to cross a year boundary without stepping through twelve `‹ ›`
/// taps. The chevrons stay for the common one-month move.
///
/// When [isPayCycle] is true (i.e. monthStartDay != 1), shows the period date
/// range with a "Pay cycle" caption below it (docs/Roadmap.md Phase 1).
///
/// Extracted from `calendar_page.dart` (`docs/Conventions.md` §1).
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
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context);

    final String label;
    if (isPayCycle) {
      label = _formatPeriod(period, locale);
    } else {
      label = MaterialLocalizations.of(context)
          .formatMonthYear(DateTime(period.start.year, period.start.month));
    }

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(AppIcons.chevronLeft),
          tooltip: strings('calendarPreviousMonth'),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.borderSm,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPickMonth,
              // A tooltip doubles as the accessibility hint: a bare tappable
              // month name gives no clue that it opens a picker.
              child: Tooltip(
                message: strings('calendarPickMonth'),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44.0),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              // The caret is the affordance; without it the label reads
                              // as a heading, not a control.
                              Icon(
                                AppIcons.dropdown,
                                size: 20,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                          if (isPayCycle) ...<Widget>[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              strings('calendarPayCycle'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(AppIcons.chevronRight),
          tooltip: strings('calendarNextMonth'),
        ),
      ],
    );
  }

  static String _formatPeriod(BudgetPeriod period, Locale locale) {
    final startDt = period.start.toDateTime();
    final endDt = period.end.toDateTime();
    final localeStr = locale.toLanguageTag();
    if (period.start.year != period.end.year) {
      final startYear = DateFormat.yMMMd(localeStr).format(startDt);
      final endYear = DateFormat.yMMMd(localeStr).format(endDt);
      return '$startYear – $endYear';
    }
    final startFmt = DateFormat.MMMd(localeStr).format(startDt);
    final endFmt = DateFormat.MMMd(localeStr).format(endDt);
    return '$startFmt – $endFmt';
  }
}
