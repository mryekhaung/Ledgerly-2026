import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_select_field.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:material_ui/material_ui.dart';

/// Total-vs-category scope picker with the category dropdown.
///
/// Extracted from `budget_form_page.dart` (`docs/Conventions.md` §1).
class BudgetScopeSection extends StatelessWidget {
  /// Creates a [BudgetScopeSection].
  const BudgetScopeSection({
    required this.isTotal,
    required this.categories,
    required this.selectedCategoryId,
    required this.onScopeChanged,
    required this.onCategoryChanged,
    super.key,
  });

  /// Whether this is an overall budget.
  final bool isTotal;

  /// Pickable expense categories.
  final List<Category> categories;

  /// The dropdown's initial value (falls back to the first category).
  final String? selectedCategoryId;

  /// Called with the new scope.
  final ValueChanged<bool> onScopeChanged;

  /// Called with the picked category id.
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          strings('budgetFieldCategory'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedTabs<bool>(
          tabs: <SegmentedTab<bool>>[
            SegmentedTab<bool>(
              value: true,
              label: strings('budgetsTotal'),
              icon: AppIcons.insights,
            ),
            SegmentedTab<bool>(
              value: false,
              label: strings('budgetsCategory'),
              icon: AppIcons.category,
            ),
          ],
          selected: isTotal,
          onChanged: onScopeChanged,
        ),
        const SizedBox(height: AppSpacing.md),

        // If Category Budget, render Category Dropdown Selector
        if (!isTotal) ...<Widget>[
          AppSelectField<String>(
            value: selectedCategoryId,
            decoration: InputDecoration(
              labelText: strings('budgetFieldCategory'),
              border: const OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
              ),
            ),
            options: categories.map((cat) {
              return AppSelectOption<String>(
                value: cat.id,
                child: Row(
                  children: <Widget>[
                    CategoryGem(
                      colorValue: cat.colorValue,
                      iconKey: cat.iconKey,
                      size: CategoryGemSize.sm,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(cat.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onCategoryChanged(val);
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
