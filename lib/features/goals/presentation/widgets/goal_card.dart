import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/app_dialog.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/delete_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/set_goal_archived.dart';
import 'package:ledgerly/features/goals/presentation/providers/goals_providers.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_card/header.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_card/progress.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_contribution_dialog.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Card displaying a savings goal with visual progress and management actions.
///
/// Composition root only: header and progress live in `widgets/goal_card/`
/// (`docs/Conventions.md` §1).
class GoalCard extends ConsumerWidget {
  /// Creates the card.
  const GoalCard({required this.goal, this.onTap, this.onEdit, super.key});

  /// The goal to render.
  final SavingsGoal goal;

  /// Called on tap (defaults to the contribution dialog).
  final VoidCallback? onTap;

  /// Called to edit.
  final VoidCallback? onEdit;

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final confirmed = await AppDialog.confirm(
      context: context,
      title: strings('deleteGoal'),
      message: strings('deleteGoalConfirm'),
      confirmLabel: strings('deleteGoal'),
      cancelLabel: strings('actionCancel'),
      isDestructive: true,
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

  void _showContribution(BuildContext context, GoalContributionMode mode) {
    unawaited(
      GoalContributionDialog.show(context, goal: goal, initialMode: mode),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppThemeColors.of(context);
    final now = DateTime.now();
    final today = LocalDate(now.year, now.month, now.day);
    final isCompleted = goal.isCompleted;
    final isOverdue = goal.isOverdue(today);
    final daysRemaining = goal.daysRemaining(today);
    final percent = (goal.progress * 100).toInt();

    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      border: Border.all(
        color: isCompleted
            ? colors.moneyIn.withValues(alpha: 0.5)
            : colors.border,
        width: isCompleted ? 1.5 : 1,
      ),
      onTap:
          onTap ??
          () => _showContribution(context, GoalContributionMode.deposit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoalCardHeader(
            goal: goal,
            isCompleted: isCompleted,
            isOverdue: isOverdue,
            daysRemaining: daysRemaining,
            onDeposit: () =>
                _showContribution(context, GoalContributionMode.deposit),
            onWithdraw: () =>
                _showContribution(context, GoalContributionMode.withdraw),
            onEdit: onEdit,
            onToggleArchive: () =>
                unawaited(_handleToggleArchive(context, ref)),
            onDelete: () => unawaited(_handleDelete(context, ref)),
          ),
          GoalProgressSection(
            goal: goal,
            isCompleted: isCompleted,
            percent: percent,
          ),
        ],
      ),
    );
  }
}
