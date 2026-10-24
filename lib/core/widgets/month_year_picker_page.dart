import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveAppBarAction;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_period_selector.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:material_ui/material_ui.dart';

/// Picks a month and year, returning the **first day** of the chosen month.
///
/// The counterpart to `MonthDayPickerPage`: that one answers "which day in this
/// month", this one answers "which month". They are separate because the
/// calendar screen already owns day selection (a tap on the grid) — what it
/// cannot do is cross a year boundary without stepping 12 times through the
/// `‹ ›` buttons.
///
/// Hand-rolled for the same reason as the day picker: `showDatePicker` brings
/// Material's own colour roles and typography onto the screen, which
/// `docs/Agent.md` §3.9 forbids, and the app's navigation model is already a
/// calendar, so the picker should look like the screen the user came from.
///
/// Returns null when dismissed without choosing.
class MonthYearPickerPage extends StatefulWidget {
  /// Creates the picker.
  const MonthYearPickerPage({
    required this.initialMonth,
    this.selectableYearRange = 50,
    super.key,
  });

  /// The month to open on and highlight.
  final LocalDate initialMonth;

  /// How many years either side of [initialMonth] may be chosen.
  ///
  /// Bounded rather than unbounded because `LocalDate` supports years 1–9999 and
  /// a picker listing ten thousand years is not a picker. Fifty years each way
  /// covers a working lifetime of records.
  final int selectableYearRange;

  @override
  State<MonthYearPickerPage> createState() => _MonthYearPickerPageState();
}

class _MonthYearPickerPageState extends State<MonthYearPickerPage> {
  /// The year whose months are on screen. Independent of the chosen month
  /// until the user actually taps one — browsing years is not choosing.
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  int get _minYear {
    final candidate = widget.initialMonth.year - widget.selectableYearRange;
    return candidate < 1 ? 1 : candidate;
  }

  int get _maxYear {
    final candidate = widget.initialMonth.year + widget.selectableYearRange;
    return candidate > 9999 ? 9999 : candidate;
  }

  bool get _canGoBack => _year > _minYear;
  bool get _canGoForward => _year < _maxYear;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final locale = Localizations.localeOf(context);

    return AppScaffold(
      title: strings('calendarPickMonth'),
      adaptiveActions: <AdaptiveAppBarAction>[
        AdaptiveAppBarAction(
          title: strings('calendarToday'),
          label: strings('calendarToday'),
          onPressed: () => context.pop(LocalDate.fromDateTime(DateTime.now())),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: <Widget>[
          AppPeriodSelector(
            period: BudgetPeriod(
              start: LocalDate(_year, 1, 1),
              end: LocalDate(_year, 12, 31),
            ),
            isPayCycle: false,
            labelOverride: '$_year',
            previousTooltip: strings('calendarPreviousYear'),
            nextTooltip: strings('calendarNextYear'),
            onPrevious: _canGoBack ? () => setState(() => _year--) : null,
            onNext: _canGoForward ? () => setState(() => _year++) : null,
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.2,
            children: <Widget>[
              for (var month = 1; month <= 12; month++)
                _MonthCell(
                  label: DateFormat.MMMM(locale.toLanguageTag())
                      .format(DateTime(_year, month)),
                  isSelected:
                      _year == widget.initialMonth.year &&
                      month == widget.initialMonth.month,
                  onTap: () => context.pop(LocalDate(_year, month, 1)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            strings('calendarPickMonthHint'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// One month tile in the 3x4 grid.
class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return Material(
      color: isSelected ? colors.selectedFill : colors.surfaceRaised,
      borderRadius: AppRadius.borderMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected ? colors.onSelectedFill : colors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : null,
            ),
          ),
        ),
      ),
    );
  }
}
