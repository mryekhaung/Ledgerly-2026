import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:material_ui/material_ui.dart';

/// Category picker row.
///
/// Extracted from `transaction_filter_sheet.dart` (`docs/Conventions.md` §1).
class FilterCategorySection extends StatelessWidget {
  /// Creates a [FilterCategorySection].
  const FilterCategorySection({
    required this.selectedCategory,
    required this.onPick,
    required this.onClear,
    super.key,
  });

  /// The currently picked category, if any.
  final Category? selectedCategory;

  /// Called to open the category picker.
  final VoidCallback onPick;

  /// Called to clear the picked category.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final selectedCategory = this.selectedCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          strings('filterCategory'),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onPick,
          borderRadius: AppRadius.borderMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: <Widget>[
                if (selectedCategory case final cat?) ...<Widget>[
                  CategoryGem(
                    colorValue: cat.colorValue,
                    iconKey: cat.iconKey,
                    size: CategoryGemSize.sm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close, size: 18),
                    onPressed: onClear,
                  ),
                ] else ...<Widget>[
                  Icon(
                    AppIcons.category,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      strings('transactionCategoryChoose'),
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(AppIcons.chevronRight, size: 20),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
