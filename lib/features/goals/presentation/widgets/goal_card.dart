import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/delete_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/set_goal_archived.dart';
import 'package:ledgerly/features/goals/presentation/providers/goals_providers.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_contribution_dialog.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Card displaying a savings goal with visual progress and management actions.
class GoalCard extends ConsumerWidget {
  const GoalCard({required this.goal, this.onTap, this.onEdit, super.key});

  final SavingsGoal goal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings('deleteGoal')),
        content: Text(strings('deleteGoalConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.of(context).moneyOut,
            ),
            child: Text(strings('deleteGoal')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final deleteUseCase = ref.read(deleteSavingsGoalProvider);
      final result = await deleteUseCase(DeleteSavingsGoalParams(id: goal.id));
      if (context.mounted) {
        result.fold(
          onSuccess: (_) => AppFeedback.confirm(
            context,
            message: strings('goalDeletedSuccess'),
          ),
          onErr: (f) => AppFeedback.failure(context, message: f.message),
        );
      }
    }
  }

  Future<void> _handleToggleArchive(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final useCase = ref.read(setGoalArchivedProvider);
    final result = await useCase(
      SetGoalArchivedParams(id: goal.id, archived: !goal.isArchived),
    );
    if (context.mounted) {
      result.fold(
        onSuccess: (_) => AppFeedback.confirm(
          context,
          message: goal.isArchived
              ? strings('unarchiveGoal')
              : strings('archiveGoal'),
        ),
        onErr: (f) => AppFeedback.failure(context, message: f.message),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final now = DateTime.now();
    final today = LocalDate(now.year, now.month, now.day);
    final isCompleted = goal.isCompleted;
    final isOverdue = goal.isOverdue(today);
    final daysRemaining = goal.daysRemaining(today);
    final percent = (goal.progress * 100).toInt();

    final goalColor = Color(goal.colorValue);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? colors.moneyIn.withValues(alpha: 0.5)
              : colors.border,
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      color: colors.surfaceRaised,
      child: InkWell(
        onTap: onTap ?? () => GoalContributionDialog.show(context, goal: goal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Gem + Title + Menu
              Row(
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.moneyIn.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '100%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.moneyIn,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Deadline / Days info
                        if (goal.targetDate != null)
                          Text(
                            isOverdue
                                ? AppStrings.fill(context, 'goalDaysOverdue', {
                                    'days': daysRemaining?.abs() ?? 0,
                                  })
                                : daysRemaining != null && daysRemaining >= 0
                                ? AppStrings.fill(context, 'goalDaysLeft', {
                                    'days': daysRemaining,
                                  })
                                : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue
                                  ? colors.moneyOut
                                  : colors.textSecondary,
                              fontWeight: isOverdue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Quick Deposit Button
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: colors.moneyIn,
                      size: 28,
                    ),
                    tooltip: strings('depositAction'),
                    onPressed: () => GoalContributionDialog.show(
                      context,
                      goal: goal,
                      initialMode: GoalContributionMode.deposit,
                    ),
                  ),

                  // Popup Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case 'deposit':
                          unawaited(
                            GoalContributionDialog.show(
                              context,
                              goal: goal,
                              initialMode: GoalContributionMode.deposit,
                            ),
                          );
                        case 'withdraw':
                          unawaited(
                            GoalContributionDialog.show(
                              context,
                              goal: goal,
                              initialMode: GoalContributionMode.withdraw,
                            ),
                          );
                        case 'edit':
                          onEdit?.call();
                        case 'archive':
                          unawaited(_handleToggleArchive(context, ref));
                        case 'delete':
                          unawaited(_handleDelete(context, ref));
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'deposit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: colors.moneyIn,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(strings('depositTitle')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'withdraw',
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: colors.moneyOut,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(strings('withdrawTitle')),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(strings('editGoal')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              goal.isArchived
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              goal.isArchived
                                  ? strings('unarchiveGoal')
                                  : strings('archiveGoal'),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: colors.moneyOut,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              strings('deleteGoal'),
                              style: TextStyle(color: colors.moneyOut),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
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
                  Row(
                    children: [
                      AmountText(
                        goal.currentAmount,
                        style: AmountStyle.row,
                        signed: false,
                        color: isCompleted
                            ? colors.moneyIn
                            : colors.textPrimary,
                      ),
                      Text(
                        ' / ',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      AmountText(
                        goal.targetAmount,
                        style: AmountStyle.row,
                        signed: false,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? colors.moneyIn
                          : colors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Remaining hint or Completed badge
              if (isCompleted) ...[
                const SizedBox(height: 4),
                Text(
                  strings('goalCompleted'),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.moneyIn,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  AppStrings.fill(context, 'goalRemaining', {
                    'amount': '${goal.remainingAmount.amountMinor}',
                  }),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
