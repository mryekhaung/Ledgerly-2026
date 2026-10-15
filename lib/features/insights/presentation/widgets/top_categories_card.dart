import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/insights/domain/entities/category_breakdown.dart';
import 'package:material_ui/material_ui.dart';

/// Card listing top spending categories with progress distribution bars.
class TopCategoriesCard extends StatelessWidget {
  const TopCategoriesCard({
    required this.breakdowns,
    required this.currency,
    super.key,
  });

  final List<CategoryBreakdown> breakdowns;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    if (breakdowns.isEmpty) {
      return const SizedBox.shrink();
    }

    final topItems = breakdowns.take(5).toList();

    // §5.2: breakdown cards are AppCards, not bespoke subtle containers.
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings('insightsTopCategories'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = topItems[index];
              final money = Money.minor(item.amountMinor, currency);
              final pct = (item.percentage * 100).toStringAsFixed(1);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CategoryGem(
                        colorValue: item.category.colorValue,
                        iconKey: item.category.iconKey,
                        size: CategoryGemSize.sm,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          item.category.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$pct%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AmountText(money, style: AmountStyle.row, signed: false),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: AppRadius.borderSm,
                    child: LinearProgressIndicator(
                      value: item.percentage.clamp(0.0, 1.0),
                      backgroundColor: colors.border.withValues(alpha: 0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(item.category.colorValue),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
