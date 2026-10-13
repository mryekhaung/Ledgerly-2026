import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
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

  /// The chosen month (1–12), highlighted in the grid.
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
    _month = widget.initialMonth.month;
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
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings('calendarPickMonth')),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.of(context)
                    .pop(LocalDate.fromDateTime(DateTime.now())),
            child: Text(strings('calendarToday')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          _YearSwitcher(
            year: _year,
            canGoBack: _canGoBack,
            canGoForward: _canGoForward,
            onPrevious: () => setState(() => _year--),
            onNext: () => setState(() => _year++),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.8,
            children: <Widget>[
              for (var month = 1; month <= 12; month++)
                _MonthCell(
                  // The month name comes from CLDR via MaterialLocalizations:
                  // 12 names x 3 locales is data the platform already has right,
                  // and duplicating it in the ARB would be 36 strings to keep
                  // in sync for no gain (matches `MonthDayPickerPage`).
                  label: localizations.formatMonthYear(DateTime(_year, month)),
                  isSelected: month == _month,
                  onTap: () =>
                      Navigator.of(context).pop(LocalDate(_year, month, 1)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            strings('calendarPickMonthHint'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The `< 2026 >` year header.
class _YearSwitcher extends StatelessWidget {
  const _YearSwitcher({
    required this.year,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final int year;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Row(
      children: <Widget>[
        IconButton(
          // Null disables the button, which is the honest state at the range
          // edge — the alternative is a tap that silently does nothing.
          onPressed: canGoBack ? onPrevious : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: strings('calendarPreviousYear'),
        ),
        Expanded(
          child: Text(
            '$year',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: canGoForward ? onNext : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: strings('calendarNextYear'),
        ),
      ],
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
      color: isSelected ? colors.brandSubtle : colors.surfaceSubtle,
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
              // `brandPrimary` on a `brandSubtle` tile: the same pairing the
              // nav rail uses for its selected label, and it is the one pair
              // that keeps its contrast in *both* themes (the light and dark
              // `brandSubtle` values are far apart in luminance, so a fixed
              // `textPrimary` would fail in one of them).
              color: isSelected ? colors.brandPrimary : colors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : null,
            ),
          ),
        ),
      ),
    );
  }
}
