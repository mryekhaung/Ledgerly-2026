import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_status.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_status_pill.dart';
import 'package:material_ui/material_ui.dart';

/// Row widget representing a single category's budget progress.
class BudgetCategoryRow extends StatelessWidget {
  const BudgetCategoryRow({
    required this.progress,
    required this.onTap,
    this.onDelete,
    super.key,
  });

  final BudgetProgress progress;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    final p = progress;
    final spentMoney = Money.minor(p.spentMinor, p.budget.currency);
    final limitMoney = Money.minor(p.budget.amountMinor, p.budget.currency);
    final remainingMoney = Money.minor(
      p.remainingMinor.abs(),
      p.budget.currency,
    );

    final statusColor = switch (p.status) {
      BudgetStatus.safe => colors.moneyIn,
      BudgetStatus.warning => colors.warning,
      BudgetStatus.exceeded => colors.moneyOut,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: p.isOverBudget
                ? colors.moneyOut.withValues(alpha: 0.4)
                : colors.border.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                CategoryGem(
                  colorValue: p.categoryColor ?? 0xFF12987C,
                  iconKey: p.categoryIcon ?? 'tag',
                  size: CategoryGemSize.md,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        p.categoryName ?? strings('budgetsCategory'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          AmountText(
                            spentMoney,
                            style: AmountStyle.row,
                            signed: false,
                          ),
                          Text(
                            ' / ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          AmountText(
                            limitMoney,
                            style: AmountStyle.row,
                            signed: false,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                BudgetStatusPill(status: p.status),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      AppIcons.more,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onTap();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: <Widget>[
                            const Icon(AppIcons.edit, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Text(strings('budgetsEdit')),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: <Widget>[
                            Icon(
                              AppIcons.destructive,
                              size: 18,
                              color: colors.moneyOut,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              strings('budgetsDelete'),
                              style: AppTypography.body.copyWith(
                                color: colors.moneyOut,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: LinearProgressIndicator(
                value: p.progressFraction,
                minHeight: 7,
                backgroundColor: colors.border.withValues(alpha: 0.35),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${p.spentPercentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      p.isOverBudget
                          ? strings('budgetStatusExceeded')
                          : strings('budgetRemaining'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AmountText(
                      remainingMoney,
                      style: AmountStyle.row,
                      signed: false,
                      color: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
