import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
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
    final dateFormat = DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Frequency dropdown
        DropdownButtonFormField<RecurringFrequency>(
          initialValue: frequency,
          decoration: InputDecoration(
            labelText: strings('recurringFieldFrequency'),
            border: const OutlineInputBorder(borderRadius: AppRadius.borderMd),
          ),
          items: RecurringFrequency.values.map((freq) {
            final label = switch (freq) {
              RecurringFrequency.daily => strings('recurringFrequencyDaily'),
              RecurringFrequency.weekly => strings('recurringFrequencyWeekly'),
              RecurringFrequency.monthly => strings(
                'recurringFrequencyMonthly',
              ),
              RecurringFrequency.yearly => strings('recurringFrequencyYearly'),
            };
            return DropdownMenuItem<RecurringFrequency>(
              value: freq,
              child: Text(label),
            );
          }).toList(),
          onChanged: (freq) {
            if (freq != null) onFrequencyChanged(freq);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Start Date row
        ListTile(
          tileColor: colors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
            side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
          ),
          leading: Icon(AppIcons.calendar, color: colors.brandPrimary),
          title: Text(strings('recurringFieldStartDate')),
          // §7: dates render via intl for the active locale, never ISO.
          subtitle: Text(dateFormat.format(startDate.toDateTime())),
          trailing: const Icon(AppIcons.chevronForward, size: 14),
          onTap: onPickStart,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Has end date switch
        SwitchListTile(
          title: Text(strings('recurringFieldHasEndDate')),
          value: hasEndDate,
          onChanged: onHasEndDateChanged,
        ),

        if (hasEndDate && endDate != null) ...<Widget>[
          ListTile(
            tileColor: colors.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
              side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
            ),
            leading: Icon(AppIcons.event, color: colors.moneyOut),
            title: Text(strings('recurringFieldEndDate')),
            subtitle: Text(dateFormat.format(endDate!.toDateTime())),
            trailing: const Icon(AppIcons.chevronForward, size: 14),
            onTap: onPickEnd,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        const SizedBox(height: AppSpacing.sm),

        // Auto-add switch
        SwitchListTile(
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
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
