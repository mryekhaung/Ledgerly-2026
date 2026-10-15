import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:material_ui/material_ui.dart';

/// Direction / type segment control.
///
/// Extracted from `transaction_filter_sheet.dart` (`docs/Conventions.md` §1).
class FilterDirectionSection extends StatelessWidget {
  /// Creates a [FilterDirectionSection].
  const FilterDirectionSection({
    required this.direction,
    required this.onChanged,
    super.key,
  });

  /// The selected direction (null = all).
  final TransactionDirection? direction;

  /// Called with the new direction.
  final ValueChanged<TransactionDirection?> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          strings('categoriesKindLabel'),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedTabs<TransactionDirection?>(
          tabs: <SegmentedTab<TransactionDirection?>>[
            SegmentedTab<TransactionDirection?>(
              value: null,
              label: strings('filterAll'),
            ),
            SegmentedTab<TransactionDirection?>(
              value: TransactionDirection.expense,
              label: strings('filterExpense'),
            ),
            SegmentedTab<TransactionDirection?>(
              value: TransactionDirection.income,
              label: strings('filterIncome'),
            ),
          ],
          selected: direction,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
