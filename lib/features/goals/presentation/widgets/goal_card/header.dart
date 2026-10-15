import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_overflow_menu.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:material_ui/material_ui.dart';

/// Gem + title + deadline + deposit + menu.
///
/// Extracted from `goal_card.dart` (`docs/Conventions.md` §1).
class GoalCardHeader extends StatelessWidget {
  /// Creates a [GoalCardHeader].
  const GoalCardHeader({
    required this.goal,
    required this.isCompleted,
    required this.isOverdue,
    required this.daysRemaining,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onEdit,
    required this.onToggleArchive,
    required this.onDelete,
    super.key,
  });

  /// The goal to render.
  final SavingsGoal goal;

  /// Whether the goal is complete.
  final bool isCompleted;

  /// Whether the goal is past its target date.
  final bool isOverdue;

  /// Days left (negative when overdue), if dated.
  final int? daysRemaining;

  /// Called for a quick deposit.
  final VoidCallback onDeposit;

  /// Called for a quick withdrawal.
  final VoidCallback onWithdraw;

  /// Called to edit (may be null).
  final VoidCallback? onEdit;

  /// Called to toggle archive.
  final VoidCallback onToggleArchive;

  /// Called to delete (after the card's own confirmation).
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final remaining = daysRemaining;

    return Row(
      children: [
        CategoryGem(
          colorValue: goal.colorValue,
          iconKey: goal.iconKey,
          size: CategoryGemSize.lg,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      goal.name,
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.moneyIn.withValues(alpha: 0.15),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        '100%',
                        style: AppTypography.caption.copyWith(
                          color: colors.moneyIn,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              // Deadline / Days info
              if (goal.targetDate != null)
                Text(
                  isOverdue
                      ? AppStrings.fill(context, 'goalDaysOverdue', {
                          'days': remaining?.abs() ?? 0,
                        })
                      : remaining != null && remaining >= 0
                      ? AppStrings.fill(context, 'goalDaysLeft', {
                          'days': remaining,
                        })
                      : '',
                  style: AppTypography.label.copyWith(
                    color: isOverdue ? colors.moneyOut : colors.textSecondary,
                    fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),

        // Quick Deposit Button
        IconButton(
          icon: Icon(AppIcons.addCircle, color: colors.moneyIn, size: 28),
          tooltip: strings('depositAction'),
          onPressed: onDeposit,
        ),

        // Popup Menu
        AppOverflowMenu<String>(
          icon: AppIcons.more,
          cancelLabel: strings('actionCancel'),
          onSelected: (action) {
            switch (action) {
              case 'deposit':
                onDeposit();
              case 'withdraw':
                onWithdraw();
              case 'edit':
                onEdit?.call();
              case 'archive':
                onToggleArchive();
              case 'delete':
                onDelete();
            }
          },
          items: <OverflowMenuItem<String>>[
            OverflowMenuItem<String>(
              value: 'deposit',
              label: strings('depositTitle'),
              icon: AppIcons.decrease,
            ),
            OverflowMenuItem<String>(
              value: 'withdraw',
              label: strings('withdrawTitle'),
              icon: AppIcons.increase,
            ),
            OverflowMenuItem<String>(
              value: 'edit',
              label: strings('editGoal'),
              icon: AppIcons.edit,
            ),
            OverflowMenuItem<String>(
              value: 'archive',
              label: goal.isArchived
                  ? strings('unarchiveGoal')
                  : strings('archiveGoal'),
              icon: goal.isArchived ? AppIcons.unarchive : AppIcons.archive,
            ),
            OverflowMenuItem<String>(
              value: 'delete',
              label: strings('deleteGoal'),
              icon: AppIcons.destructive,
              destructive: true,
            ),
          ],
        ),
      ],
    );
  }
}
