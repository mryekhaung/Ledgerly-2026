import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/features/insights/domain/entities/period_comparison.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:material_ui/material_ui.dart';

/// Top summary card showing total net balance, income, expense and period-over-period delta.
class InsightSummaryCard extends StatelessWidget {
  const InsightSummaryCard({
    required this.summary,
    required this.comparison,
    required this.currency,
    super.key,
  });

  final PeriodTotal summary;
  final PeriodComparison comparison;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    final netMoney = Money.minor(summary.netMinor, currency);
    final deltaPct = comparison.expenseDeltaPercentage;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              Text(
                strings('insightsNetSavings'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (deltaPct != null) _ComparisonBadge(deltaPct: deltaPct),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AmountText(netMoney, style: AmountStyle.large, signed: true),
          const SizedBox(height: AppSpacing.md),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings('insightsTotalIncome'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AmountText(
                      Money.minor(summary.incomeMinor, currency),
                      style: AmountStyle.row,
                      signed: false,
                      color: colors.moneyIn,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings('insightsTotalExpense'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AmountText(
                      Money.minor(summary.expenseMinor, currency),
                      style: AmountStyle.row,
                      signed: false,
                      color: colors.moneyOut,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonBadge extends StatelessWidget {
  const _ComparisonBadge({required this.deltaPct});

  final double deltaPct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    final isIncrease = deltaPct > 0;
    final badgeColor = isIncrease ? colors.moneyOut : colors.moneyIn;
    final badgeBg = isIncrease ? colors.moneyOutSubtle : colors.moneyInSubtle;
    final prefix = isIncrease ? '+' : '';
    final formattedPct = '$prefix${deltaPct.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: AppRadius.borderSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isIncrease ? AppIcons.increase : AppIcons.decrease,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$formattedPct ${strings('insightsVsPreviousPeriod')}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
