import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/utils/month_grid_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The `M T W T F S S` header, rotated to match the grid's week start.
///
/// Extracted from `calendar_page.dart` (`docs/Conventions.md` §1).
class WeekdayHeader extends StatelessWidget {
  /// Creates a [WeekdayHeader].
  const WeekdayHeader({required this.weekStart, super.key});

  /// Which day opens the week.
  final GridWeekStart weekStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final localizations = MaterialLocalizations.of(context);

    // `narrowWeekdays` is Sunday-indexed (0 = S), so for a Monday-first grid the
    // columns are days 1..6 then Sunday (index 0). A Sunday-first grid is simply
    // days 0..6 in order — which is why this rotates with an offset rather than
    // reordering a literal list that would then have to be kept in two places.
    final firstIndex = weekStart == GridWeekStart.monday ? 1 : 0;

    return Row(
      children: <Widget>[
        for (var column = 0; column < DateTime.daysPerWeek; column++)
          Expanded(
            child: Center(
              child: Text(
                localizations.narrowWeekdays[(firstIndex + column) %
                    DateTime.daysPerWeek],
                // §6.2: only the **weekend** columns are `textTertiary`; the
                // working week is `textSecondary`. Painting all seven tertiary
                // made the whole header a 2.58:1 whisper on white (and 3.21:1 on
                // dark), i.e. an unreadable label, not a de-emphasised one
                // (docs/Roadmap.md §K.1-4).
                //
                // `narrowWeekdays` is Sunday-indexed (0 = Sun … 6 = Sat), so the
                // weekend columns are 0 and 6 — *not* `DateTime.saturday` /
                // `DateTime.sunday`, which are 1-based (6 and 7).
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _isWeekendColumn(firstIndex + column)
                      ? colors.textTertiary
                      : colors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Whether the grid column at [sundayIndexed] falls on a weekend.
  static bool _isWeekendColumn(int sundayIndexed) {
    final day = sundayIndexed % DateTime.daysPerWeek;
    return day == 0 || day == 6; // Sunday / Saturday
  }
}
