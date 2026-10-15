import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_filter.dart';
import 'package:material_ui/material_ui.dart';

/// Horizontal scrollable bar with active filter chips.
///
/// Extracted from `transactions_list_page.dart` (`docs/Conventions.md` §1).
class FilterChipsBar extends ConsumerWidget {
  /// Creates a [FilterChipsBar].
  const FilterChipsBar({
    required this.filter,
    required this.onDirectionSelected,
    required this.onPickCategory,
    required this.onClearCategory,
    required this.onOpenFilterSheet,
    required this.onClearAll,
    super.key,
  });

  /// The active filter.
  final TransactionFilter filter;

  /// Called when a direction chip is picked (null = all).
  final ValueChanged<TransactionDirection?> onDirectionSelected;

  /// Called when the category chip is tapped.
  final VoidCallback onPickCategory;

  /// Called when the category chip's delete affordance is tapped.
  final VoidCallback onClearCategory;

  /// Called when a chip needs the full filter sheet.
  final VoidCallback onOpenFilterSheet;

  /// Called when Clear-all is tapped.
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    Category? selectedCategory;
    if (filter.categoryId case final id?) {
      selectedCategory = ref.watch(categoryByIdProvider(id)).value;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: ResponsiveInsets.pageHorizontal(context)
          .copyWith(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          // Direction Chips
          FilterChip(
            label: Text(strings('filterAll')),
            selected: filter.direction == null,
            onSelected: (_) => onDirectionSelected(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          FilterChip(
            label: Text(strings('filterExpense')),
            selected: filter.direction == TransactionDirection.expense,
            onSelected: (selected) {
              onDirectionSelected(
                selected ? TransactionDirection.expense : null,
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          FilterChip(
            label: Text(strings('filterIncome')),
            selected: filter.direction == TransactionDirection.income,
            onSelected: (selected) {
              onDirectionSelected(
                selected ? TransactionDirection.income : null,
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),

          // Category Chip
          if (selectedCategory case final cat?) ...<Widget>[
            InputChip(
              avatar: CategoryGem(
                colorValue: cat.colorValue,
                iconKey: cat.iconKey,
                size: CategoryGemSize.sm,
              ),
              label: Text(cat.name),
              selected: true,
              onDeleted: onClearCategory,
              onPressed: onPickCategory,
            ),
          ] else ...<Widget>[
            ActionChip(
              avatar: const Icon(AppIcons.category, size: 16),
              label: Text(strings('filterCategory')),
              onPressed: onPickCategory,
            ),
          ],
          const SizedBox(width: AppSpacing.xs),

          // Date Range Chip
          ActionChip(
            avatar: const Icon(AppIcons.calendar, size: 16),
            label: Text(
              filter.startDate != null || filter.endDate != null
                  ? '${filter.startDate?.toString() ?? '...'} ~ ${filter.endDate?.toString() ?? '...'}'
                  : strings('filterDateRange'),
            ),
            backgroundColor:
                (filter.startDate != null || filter.endDate != null)
                ? colors.brandSubtle
                : null,
            onPressed: onOpenFilterSheet,
          ),
          const SizedBox(width: AppSpacing.xs),

          // Amount Chip
          if (filter.minAmountMinor != null ||
              filter.maxAmountMinor != null) ...<Widget>[
            ActionChip(
              avatar: const Icon(AppIcons.money, size: 16),
              label: Text(
                '${filter.minAmountMinor ?? 0} ~ ${filter.maxAmountMinor ?? '∞'}',
              ),
              backgroundColor: colors.brandSubtle,
              onPressed: onOpenFilterSheet,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],

          // Clear all button if any filter active
          if (filter.isActive) ...<Widget>[
            ActionChip(
              avatar: const Icon(AppIcons.close, size: 16),
              label: Text(strings('filterClearAll')),
              onPressed: onClearAll,
            ),
          ],
        ],
      ),
    );
  }
}
