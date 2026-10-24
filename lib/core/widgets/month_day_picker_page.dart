import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/utils/month_grid_layout.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:material_ui/material_ui.dart';

/// Picks a single calendar day in a month grid.
///
/// Hand-rolled rather than `showDatePicker`, for two reasons: the Material picker
/// brings its own typography and colour roles onto the screen, which
/// `docs/Agent.md` §3.9 forbids; and this app's whole navigation model is a
/// calendar, so the picker should look like the screen the user already knows.
///
/// Loads on the day the caller passes and returns the chosen [LocalDate], or
/// null when dismissed. Weeks start on Monday, matching the calendar screen.
class MonthDayPickerPage extends StatefulWidget {
  /// Creates the picker.
  const MonthDayPickerPage({required this.initialDate, super.key});

  /// The day to open on, and to show as selected.
  final LocalDate initialDate;

  @override
  State<MonthDayPickerPage> createState() => _MonthDayPickerPageState();
}

class _MonthDayPickerPageState extends State<MonthDayPickerPage> {
  /// The month being browsed — the 1st of the displayed month.
  late LocalDate _month;

  @override
  void initState() {
    super.initState();
    _month = widget.initialDate.firstDayOfMonth;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AppScaffold(
      title: strings('transactionDateLabel'),
      // The year is not selectable here: a transaction dated outside the
      // current year is almost always a typo, and the calendar screen is the
      // surface for browsing history.
      actions: <Widget>[
        AppButton(
          variant: AppButtonVariant.ghost,
          onPressed: () => context.pop(LocalDate.fromDateTime(DateTime.now())),
          label: strings('calendarToday'),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          _MonthSwitcher(
            month: _month,
            onPrevious: () => _browse(-1),
            onNext: () => _browse(1),
          ),
          const SizedBox(height: AppSpacing.md),
          const _WeekdayHeader(),
          const SizedBox(height: AppSpacing.sm),
          _MonthGrid(
            month: _month,
            selected: widget.initialDate,
            onPick: (day) => context.pop(day),
          ),
        ],
      ),
    );
  }

  /// Moves the browsed month [delta] months, clamped to the supported range.
  ///
  /// Delegates to `LocalDate.addMonths`, which already owns the month-length
  /// clamping and the year bounds — reimplementing it here would be a second
  /// copy of tested logic. It returns null past year 9999 or before year 1, and
  /// the browse simply stops there.
  void _browse(int delta) {
    final next = _month.addMonths(delta);
    if (next == null) return;
    setState(() => _month = next);
  }
}

/// The `< March 2026 >` header.
class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final LocalDate month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    // The month name comes from the platform's locale data, not from the ARB:
    // there are 12 names × 3 locales to translate, and the CLDR data is already
    // correct in all of them.
    final label = MaterialLocalizations.of(context)
        .formatMonthYear(DateTime(month.year, month.month));

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(AppIcons.chevronLeft),
          tooltip: strings('calendarPreviousMonth'),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
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
}

/// The fixed `M T W T F S S` header.
///
/// Short forms are avoided in favour of the platform's narrow weekday symbols,
/// which are one character in every supported locale and therefore never wrap.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final localizations = MaterialLocalizations.of(context);

    return Row(
      children: <Widget>[
        for (var weekday = 1; weekday <= DateTime.daysPerWeek; weekday++)
          Expanded(
            child: Center(
              child: Text(
                localizations.narrowWeekdays[weekday % DateTime.daysPerWeek],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The day cells for one month.
///
/// All the arithmetic lives in [MonthGridLayout] so it can be unit-tested; this
/// widget only turns the resulting cells into rows of tappable squares.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.onPick,
  });

  final LocalDate month;
  final LocalDate selected;
  final ValueChanged<LocalDate> onPick;

  @override
  Widget build(BuildContext context) {
    final cells = MonthGridLayout.cells(month);
    final rowCount = cells.length ~/ MonthGridLayout.daysPerWeek;

    return Column(
      children: <Widget>[
        for (var row = 0; row < rowCount; row++)
          Row(
            children: <Widget>[
              for (
                var column = 0;
                column < MonthGridLayout.daysPerWeek;
                column++
              )
                Expanded(
                  child: switch (cells[row * MonthGridLayout.daysPerWeek +
                      column]) {
                    // A blank keeps the grid's rhythm without offering a target
                    // the user could tap.
                    null => const SizedBox(height: AppSpacing.xxxl),
                    final day => _DayCell(
                      day: day,
                      isSelected: day.value == selected.value,
                      onTap: () => onPick(day),
                    ),
                  },
                ),
            ],
          ),
      ],
    );
  }
}

/// One tappable day in the grid.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final LocalDate day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colors.brandPrimary : null,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? colors.textOnBrand : colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
