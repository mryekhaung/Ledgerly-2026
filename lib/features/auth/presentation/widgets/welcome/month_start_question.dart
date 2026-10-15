import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/auth/presentation/widgets/welcome/day_grid_selector.dart';
import 'package:material_ui/material_ui.dart';

/// First-run question: month start day with live period preview
/// (Design.md §6.6).
///
/// Extracted from `welcome_page.dart` (`docs/Conventions.md` §1).
class MonthStartQuestion extends StatelessWidget {
  /// Creates a [MonthStartQuestion].
  const MonthStartQuestion({
    required this.selectedDay,
    required this.onSelect,
    required this.periodPreview,
    super.key,
  });

  /// The selected start day.
  final int selectedDay;

  /// Called with the picked day.
  final ValueChanged<int> onSelect;

  /// The pre-formatted current-period preview string.
  final String periodPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(AppIcons.calendar, size: 20, color: colors.brandPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  strings('welcomeMonthStartQuestion'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings('welcomeMonthStartHelp'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Day chips 1–28
          DayGridSelector(selectedDay: selectedDay, onSelect: onSelect),
          const SizedBox(height: AppSpacing.md),

          // Live preview text
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(AppIcons.info, size: 16, color: colors.brandPrimary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppStrings.fill(context, 'monthStartsOnCurrentPeriod', {
                      'range': periodPreview,
                    }),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
