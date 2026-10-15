import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// The 7×4 grid of day chips (1–28).
///
/// Extracted from `month_starts_on_page.dart` (`docs/Conventions.md` §1).
class DayGrid extends StatelessWidget {
  /// Creates a [DayGrid].
  const DayGrid({required this.selectedDay, required this.onSelect, super.key});

  /// The selected start day.
  final int selectedDay;

  /// Called with the picked day.
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 7 columns to match standard calendar layout.
        const columns = 7;
        const totalSpacing = AppSpacing.sm * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;
        // Keep minimum touch target 44×44 (docs/Design.md §5.7).
        final chipSize = itemWidth < 44 ? 44.0 : itemWidth;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (var day = 1; day <= 28; day++)
              _DayChip(
                day: day,
                isSelected: day == selectedDay,
                size: chipSize,
                colors: colors,
                theme: theme,
                onTap: () => onSelect(day),
              ),
          ],
        );
      },
    );
  }
}

/// One day button inside the grid.
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isSelected,
    required this.size,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final double size;
  final AppColors colors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$day',
      child: Material(
        color: isSelected ? colors.brandSubtle : colors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: size,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderMd,
              border: Border.all(
                color: isSelected ? colors.brandPrimary : colors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? colors.brandPrimary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
