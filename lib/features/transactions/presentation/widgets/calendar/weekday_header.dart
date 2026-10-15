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
