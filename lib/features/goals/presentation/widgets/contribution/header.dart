import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_contribution_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Title + goal balance header.
///
/// Extracted from `goal_contribution_dialog.dart` (`docs/Conventions.md` §1).
class ContributionHeader extends StatelessWidget {
  /// Creates a [ContributionHeader].
  const ContributionHeader({required this.mode, required this.goal, super.key});

  /// Deposit or withdraw.
  final GoalContributionMode mode;

  /// The goal being adjusted.
  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mode == GoalContributionMode.deposit
                    ? strings('depositTitle')
                    : strings('withdrawTitle'),
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                goal.name,
                style: AppTypography.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Current saved amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              strings('goalCurrentAmountLabel'),
              style: AppTypography.label.copyWith(color: colors.textSecondary),
            ),
            AmountText(
              goal.currentAmount,
              style: AmountStyle.row,
              signed: false,
            ),
          ],
        ),
      ],
    );
  }
}
