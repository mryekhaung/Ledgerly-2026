import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_status.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_status_pill.dart';
import 'package:material_ui/material_ui.dart';

/// Hero summary card displaying overall period budget progress.
class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({
    required this.progress,
    required this.onTapSetTotal,
    this.currency = CurrencyCode.mmk,
    super.key,
  });

  final BudgetProgress? progress;
  final VoidCallback onTapSetTotal;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    if (progress == null) {
      return AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.brandPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.insights,
                color: colors.brandPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings('budgetOverallSummary'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    strings('budgetTotalOption'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onTapSetTotal,
              icon: const Icon(AppIcons.add, size: 16),
              label: Text(strings('budgetsNew')),
              style: TextButton.styleFrom(foregroundColor: colors.brandPrimary),
            ),
          ],
        ),
      );
    }

    final p = progress!;
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

    // Calculate days remaining in period for daily safe spend guidance
    final today = LocalDate.fromDateTime(DateTime.now());
    final daysRemaining =
        p.period.end.toUtcDateTime().difference(today.toUtcDateTime()).inDays +
        1;
    final dailySpendMinor = p.dailyRemainingMinor(
      daysRemaining > 0 ? daysRemaining : 1,
    );

    return AppCard(
      border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                strings('budgetOverallSummary'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              BudgetStatusPill(status: p.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              AmountText(spentMoney, style: AmountStyle.large, signed: false),
              const SizedBox(width: AppSpacing.xs),
              Text(
                ' / ',
                style: theme.textTheme.titleMedium?.copyWith(
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
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.borderSm,
            child: LinearProgressIndicator(
              value: p.progressFraction,
              minHeight: 10,
              backgroundColor: colors.border.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${p.spentPercentage.toStringAsFixed(1)}% ${strings('budgetSpent').toLowerCase()}',
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
                  const SizedBox(width: AppSpacing.xs),
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
          if (!p.isOverBudget &&
              dailySpendMinor > 0 &&
              daysRemaining > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.brandPrimary.withValues(alpha: 0.08),
                borderRadius: AppRadius.borderSm,
              ),
              child: Row(
                children: <Widget>[
                  Icon(AppIcons.calendar, size: 14, color: colors.brandPrimary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${strings('budgetDailyRemaining')}: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AmountText(
                    Money.minor(dailySpendMinor, p.budget.currency),
                    style: AmountStyle.row,
                    signed: false,
                    color: colors.brandPrimary,
                  ),
                  Text(
                    ' / day ($daysRemaining days)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
