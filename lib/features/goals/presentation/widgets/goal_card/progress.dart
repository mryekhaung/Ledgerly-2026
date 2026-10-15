import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/money_formatter.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:material_ui/material_ui.dart';

/// Progress bar, amounts row and remaining/completed hint.
///
/// Extracted from `goal_card.dart` (`docs/Conventions.md` §1).
class GoalProgressSection extends StatelessWidget {
  /// Creates a [GoalProgressSection].
  const GoalProgressSection({
    required this.goal,
    required this.isCompleted,
    required this.percent,
    super.key,
  });

  /// The goal to render.
  final SavingsGoal goal;

  /// Whether the goal is complete.
  final bool isCompleted;

  /// The progress percentage (0–100).
  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final goalColor = Color(goal.colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.md),

        // Progress Bar
        ClipRRect(
          borderRadius: AppRadius.borderSm,
          child: LinearProgressIndicator(
            value: goal.progress,
            minHeight: 8,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? colors.moneyIn : goalColor,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Bottom amounts row: Current / Target + Percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: AmountText(
                      goal.currentAmount,
                      style: AmountStyle.row,
                      signed: false,
                      color: isCompleted ? colors.moneyIn : colors.textPrimary,
                    ),
                  ),
                  Text(
                    ' / ',
                    style: AppTypography.label.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Flexible(
                    child: AmountText(
                      goal.targetAmount,
                      style: AmountStyle.row,
                      signed: false,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$percent%',
              style: AppTypography.label.copyWith(
                color: isCompleted ? colors.moneyIn : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // Remaining hint or Completed badge
        if (isCompleted) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings('goalCompleted'),
            style: AppTypography.label.copyWith(color: colors.moneyIn),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.fill(context, 'goalRemaining', {
              // `goalRemaining` takes a *formatted* amount: raw minor units
              // render "2000000 remaining" instead of "2,000,000 Ks remaining",
              // and drop the currency entirely (docs/Design.md §5.4).
              'amount': MoneyFormatter(
                locale: Localizations.localeOf(context).toLanguageTag(),
              ).format(goal.remainingAmount),
            }),
            style: AppTypography.label.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}
