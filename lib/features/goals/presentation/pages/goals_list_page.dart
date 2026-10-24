import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveTabBarView;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/presentation/providers/goals_providers.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_card.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:material_ui/material_ui.dart';

/// Hub page displaying savings goals organized into Active, Completed, and Archived tabs.
class GoalsListPage extends ConsumerStatefulWidget {
  const GoalsListPage({super.key});

  @override
  ConsumerState<GoalsListPage> createState() => _GoalsListPageState();
}

class _GoalsListPageState extends ConsumerState<GoalsListPage> {
  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    final activeGoalsAsync = ref.watch(activeGoalsProvider);
    final completedGoalsAsync = ref.watch(completedGoalsProvider);
    final archivedGoalsAsync = ref.watch(archivedGoalsProvider);

    return AppScaffold(
      title: strings('savingsGoalsTitle'),
      body: AdaptiveTabBarView(
        tabs: <String>[
          strings('savingsGoalsActiveTab'),
          strings('savingsGoalsCompletedTab'),
          strings('savingsGoalsArchivedTab'),
        ],
        selectedColor: colors.moneyIn,
        selectedLabelColor: colors.textOnBrand,
        unselectedColor: colors.textSecondary,
        backgroundColor: colors.surface,
        children: <Widget>[
          _GoalsTab(
            goalsAsync: activeGoalsAsync,
            emptyTitle: strings('emptyGoalsTitle'),
            emptyMessage: strings('emptyGoalsMessage'),
            showCreateAction: true,
          ),
          _GoalsTab(
            goalsAsync: completedGoalsAsync,
            emptyTitle: strings('emptyCompletedGoals'),
            emptyMessage: strings('emptyCompletedGoals'),
            showCreateAction: false,
          ),
          _GoalsTab(
            goalsAsync: archivedGoalsAsync,
            emptyTitle: strings('emptyArchivedGoals'),
            emptyMessage: strings('emptyArchivedGoals'),
            showCreateAction: false,
          ),
        ],
      ),
      floatingActionButton: activeGoalsAsync.maybeWhen(
        data: (goals) => goals.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.goalsNew),
                backgroundColor: colors.moneyIn,
                foregroundColor: colors.textOnBrand,
                icon: const Icon(AppIcons.add),
                label: Text(strings('newGoal')),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab({
    required this.goalsAsync,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.showCreateAction,
  });

  final AsyncValue<List<SavingsGoal>> goalsAsync;
  final String emptyTitle;
  final String emptyMessage;
  final bool showCreateAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.goal,
                    size: 64,
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    emptyTitle,
                    style: AppTypography.title.copyWith(
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    emptyMessage,
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (showCreateAction) ...[
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.goalsNew),
                      icon: const Icon(AppIcons.add),
                      label: Text(strings('newGoal')),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.moneyIn,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            return GoalCard(
              goal: goal,
              onEdit: () => context.push('/goals/edit/${goal.id}'),
            );
          },
        );
      },
      loading: () => const LoadingPlaceholder(),
      // §5.11: inline banner with plain-language message + Retry —
      // never a raw exception dump.
      error: (_, _) => ErrorBanner(
        message: strings('stateErrorBody'),
        retryLabel: strings('stateErrorRetry'),
        onRetry: () {
          ref.invalidate(activeGoalsProvider);
          ref.invalidate(completedGoalsProvider);
          ref.invalidate(archivedGoalsProvider);
        },
      ),
    );
  }
}
