import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// Day chips 1–28 for the pay-cycle start question.
///
/// Extracted from `welcome_page.dart` (`docs/Conventions.md` §1).
class DayGridSelector extends StatelessWidget {
  /// Creates a [DayGridSelector].
  const DayGridSelector({
    required this.selectedDay,
    required this.onSelect,
    super.key,
  });

  /// The selected start day.
  final int selectedDay;

  /// Called with the picked day.
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 7;
        const totalSpacing = AppSpacing.xs * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;
        final chipSize = itemWidth < 38 ? 38.0 : itemWidth;

        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (var day = 1; day <= 28; day++)
              _SelectorDayChip(
                day: day,
                isSelected: day == selectedDay,
                size: chipSize,
                onTap: () => onSelect(day),
              ),
          ],
        );
      },
    );
  }
}

class _SelectorDayChip extends StatelessWidget {
  const _SelectorDayChip({
    required this.day,
    required this.isSelected,
    required this.size,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);
    final bg = isSelected ? colors.brandPrimary : colors.surface;
    final fg = isSelected ? colors.textOnBrand : colors.textPrimary;
    final border = isSelected ? colors.brandPrimary : colors.border;

    return Semantics(
      button: true,
      selected: isSelected,
      label: AppStrings.fill(context, 'welcomeDayChipLabel', {'day': day}),
      child: Material(
        color: bg,
        borderRadius: AppRadius.borderSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderSm,
          child: Container(
            width: size,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: border),
            ),
            child: Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
