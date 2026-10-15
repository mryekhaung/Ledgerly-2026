import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:material_ui/material_ui.dart';

/// Live preview of the budget being created/edited.
///
/// Extracted from `budget_form_page.dart` (`docs/Conventions.md` §1).
class BudgetPreviewCard extends StatelessWidget {
  /// Creates a [BudgetPreviewCard].
  const BudgetPreviewCard({
    required this.isTotal,
    required this.selectedCategory,
    required this.amountMinor,
    required this.currency,
    required this.alertThreshold,
    super.key,
  });

  /// Whether this is an overall budget.
  final bool isTotal;

  /// The chosen category, if any.
  final Category? selectedCategory;

  /// The limit in minor units.
  final int amountMinor;

  /// The budget currency.
  final CurrencyCode currency;

  /// The alert threshold 0.5–1.0.
  final double alertThreshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          strings('categoriesPreview'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (isTotal)
                    Icon(
                      AppIcons.insights,
                      color: colors.brandPrimary,
                      size: 24,
                    )
                  else if (selectedCategory != null)
                    CategoryGem(
                      colorValue: selectedCategory!.colorValue,
                      iconKey: selectedCategory!.iconKey,
                      size: CategoryGemSize.sm,
                    )
                  else
                    const Icon(AppIcons.category, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isTotal
                          ? strings('budgetsTotal')
                          : (selectedCategory?.name ??
                                strings('budgetsCategory')),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AmountText(
                    Money.minor(amountMinor, currency),
                    style: AmountStyle.row,
                    signed: false,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadius.borderSm,
                child: LinearProgressIndicator(
                  value: alertThreshold,
                  minHeight: 8,
                  backgroundColor: colors.border.withValues(alpha: 0.35),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.warning),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.fill(
                  context,
                  'budgetThresholdLive',
                  <String, Object>{'percent': (alertThreshold * 100).round()},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
