import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
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
              child: OutlinedButton(
                onPressed: onPickStart,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.md,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMd,
                  ),
                ),
                child: Text(
                  startDate == null
                      ? strings('filterStartDate')
                      : dateFormat.format(startDate!.toDateTime()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text('~'),
            ),
            Expanded(
              child: OutlinedButton(
                onPressed: onPickEnd,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.md,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMd,
                  ),
                ),
                child: Text(
                  endDate == null
                      ? strings('filterEndDate')
                      : dateFormat.format(endDate!.toDateTime()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        if (startDate != null || endDate != null) ...<Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClear,
              child: Text(strings('filterClearAll')),
            ),
          ),
        ] else ...<Widget>[const SizedBox(height: AppSpacing.lg)],
      ],
    );
  }
}
