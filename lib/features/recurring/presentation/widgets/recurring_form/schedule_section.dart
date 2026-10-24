import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveListTile;
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_material_ancestor.dart';
import 'package:ledgerly/core/widgets/app_select_field.dart';
import 'package:ledgerly/core/widgets/app_switch_tile.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:material_ui/material_ui.dart';

/// Frequency, start/end dates and auto-add switch.
///
/// Extracted from `recurring_form_page.dart` (`docs/Conventions.md` §1).
class RecurringScheduleSection extends StatelessWidget {
  /// Creates a [RecurringScheduleSection].
  const RecurringScheduleSection({
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.hasEndDate,
    required this.autoAdd,
    required this.onFrequencyChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onHasEndDateChanged,
    required this.onAutoAddChanged,
    super.key,
  });

  /// The recurrence frequency.
  final RecurringFrequency frequency;

  /// The anchor start day.
  final LocalDate startDate;

  /// The end day, if any.
  final LocalDate? endDate;

  /// Whether an end date is set.
  final bool hasEndDate;

  /// Whether occurrences auto-add.
  final bool autoAdd;

  /// Called with the new frequency.
  final ValueChanged<RecurringFrequency> onFrequencyChanged;

  /// Called to pick the start day.
  final VoidCallback onPickStart;

  /// Called to pick the end day.
  final VoidCallback onPickEnd;

  /// Called when the end-date switch flips.
  final ValueChanged<bool> onHasEndDateChanged;

  /// Called when the auto-add switch flips.
  final ValueChanged<bool> onAutoAddChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Frequency dropdown
        AppSelectField<RecurringFrequency>(
          value: frequency,
          decoration: InputDecoration(
            labelText: strings('recurringFieldFrequency'),
            border: const OutlineInputBorder(borderRadius: AppRadius.borderMd),
          ),
          options: RecurringFrequency.values.map((freq) {
            final label = switch (freq) {
              RecurringFrequency.daily => strings('recurringFrequencyDaily'),
              RecurringFrequency.weekly => strings('recurringFrequencyWeekly'),
              RecurringFrequency.monthly => strings(
                'recurringFrequencyMonthly',
              ),
              RecurringFrequency.yearly => strings('recurringFrequencyYearly'),
            };
            return AppSelectOption<RecurringFrequency>(
              value: freq,
              child: Text(label),
            );
          }).toList(),
          onChanged: (freq) {
            if (freq != null) onFrequencyChanged(freq);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: colors.border.withValues(alpha: 0.7)),
          ),
          child: Material(
            color: colors.surfaceRaised,
            borderRadius: AppRadius.borderLg,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                _DatePickerTile(
                  icon: AppIcons.calendar,
                  iconColor: colors.brandPrimary,
                  title: strings('recurringFieldStartDate'),
                  date: startDate,
                  onTap: onPickStart,
                ),
                Divider(height: 1, indent: AppSpacing.lg, color: colors.border),
                AppSwitchTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  title: Text(strings('recurringFieldHasEndDate')),
                  value: hasEndDate,
                  onChanged: onHasEndDateChanged,
                ),
                if (hasEndDate && endDate != null) ...<Widget>[
                  Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    color: colors.border,
                  ),
                  _DatePickerTile(
                    icon: AppIcons.event,
                    iconColor: colors.moneyOut,
                    title: strings('recurringFieldEndDate'),
                    date: endDate!,
                    onTap: onPickEnd,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: colors.border.withValues(alpha: 0.7)),
          ),
          child: Material(
            color: colors.surfaceRaised,
            borderRadius: AppRadius.borderLg,
            clipBehavior: Clip.antiAlias,
            child: AppSwitchTile(
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
              title: Text(strings('recurringFieldAutoAdd')),
              subtitle: Text(
                strings('recurringFieldAutoAddDesc'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              value: autoAdd,
              onChanged: onAutoAddChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final LocalDate date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = MaterialLocalizations.of(context)
        .formatMediumDate(date.toDateTime());
    final colors = AppThemeColors.of(context);

    return AppMaterialAncestor(
      child: AdaptiveListTile(
        backgroundColor: Colors.transparent,
        separatorColor: colors.border,
        hideBottomDivider: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: Text(dateLabel),
        trailing: const Icon(AppIcons.chevronForward, size: 18),
        onTap: onTap,
      ),
    );
  }
}
