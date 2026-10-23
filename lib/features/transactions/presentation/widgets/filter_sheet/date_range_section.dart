import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:material_ui/material_ui.dart';

/// Start/end date pickers with a clear affordance.
///
/// Extracted from `transaction_filter_sheet.dart` (`docs/Conventions.md` §1).
class FilterDateRangeSection extends StatelessWidget {
  /// Creates a [FilterDateRangeSection].
  const FilterDateRangeSection({
    required this.startDate,
    required this.endDate,
    required this.dateFormat,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClear,
    super.key,
  });

  /// The picked start day, if any.
  final LocalDate? startDate;

  /// The picked end day, if any.
  final LocalDate? endDate;

  /// Locale-aware day formatter (owned by the sheet).
  final DateFormat dateFormat;

  /// Called to pick the start day.
  final VoidCallback onPickStart;

  /// Called to pick the end day.
  final VoidCallback onPickEnd;

  /// Called to clear both days.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          strings('filterDateRange'),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                variant: AppButtonVariant.secondary,
                onPressed: onPickStart,
                isExpanded: true,
                label: startDate == null
                    ? strings('filterStartDate')
                    : dateFormat.format(startDate!.toDateTime()),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text('~'),
            ),
            Expanded(
              child: AppButton(
                variant: AppButtonVariant.secondary,
                onPressed: onPickEnd,
                isExpanded: true,
                label: endDate == null
                    ? strings('filterEndDate')
                    : dateFormat.format(endDate!.toDateTime()),
              ),
            ),
          ],
        ),
        if (startDate != null || endDate != null) ...<Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              variant: AppButtonVariant.ghost,
              onPressed: onClear,
              label: strings('filterClearAll'),
            ),
          ),
        ] else ...<Widget>[const SizedBox(height: AppSpacing.lg)],
      ],
    );
  }
}
