import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/budgets/presentation/providers/budget_providers.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_category_row.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_period_selector.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_summary_card.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:material_ui/material_ui.dart';

/// Main Budgets screen displaying overall period budget and category caps.
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String budgetId,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings('budgetConfirmDelete')),
        content: Text(strings('budgetConfirmDeleteMessage')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.of(context).moneyOut,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings('budgetsDelete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(budgetActionNotifierProvider.notifier)
          .deleteBudget(budgetId);
      if (success && context.mounted) {
        AppFeedback.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings('budgetDeletedSuccess'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    final currentPeriod = ref.watch(budgetPeriodProvider);
    final totalProgress = ref.watch(totalBudgetProgressProvider);
    final categoryProgresses = ref.watch(categoryBudgetProgressListProvider);
    final isPayCycle = ref.watch(monthStartDayProvider) != 1;
    final currency = ref.watch(currencyProvider);
    final hasAnyBudget = totalProgress != null || categoryProgresses.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(strings('budgetsTitle'))),
      floatingActionButton: hasAnyBudget
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.budgetNew),
              icon: const Icon(Icons.add),
              label: Text(strings('budgetsNew')),
              backgroundColor: colors.brandPrimary,
              foregroundColor: colors.textOnBrand,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: <Widget>[
          BudgetPeriodSelector(
            period: currentPeriod,
            isPayCycle: isPayCycle,
            onPrevious: () =>
                ref.read(budgetPeriodProvider.notifier).previous(),
            onNext: () => ref.read(budgetPeriodProvider.notifier).next(),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!hasAnyBudget) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            StatePlaceholder(
              icon: Icons.pie_chart_outline,
              title: strings('budgetsEmptyTitle'),
              body: strings('budgetsEmptyBody'),
              action: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.budgetNew),
                icon: const Icon(Icons.add),
                label: Text(strings('budgetsNew')),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brandPrimary,
                  foregroundColor: colors.textOnBrand,
                ),
              ),
            ),
          ] else ...<Widget>[
            BudgetSummaryCard(
              progress: totalProgress,
              currency: currency,
              onTapSetTotal: () =>
                  context.push('${AppRoutes.budgetNew}?type=total'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  strings('budgetsCategory'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (categoryProgresses.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.brandPrimary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: Text(
                      '${categoryProgresses.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.brandPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (categoryProgresses.isEmpty) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.sm,
                ),
                child: Center(
                  child: Text(
                    strings('budgetsEmptyBody'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ] else ...<Widget>[
              for (final p in categoryProgresses) ...<Widget>[
                BudgetCategoryRow(
                  progress: p,
                  onTap: () => context.push('/budgets/${p.budget.id}/edit'),
                  onDelete: () => _confirmDelete(context, ref, p.budget.id),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
            const SizedBox(height: 80), // Padding for FAB
          ],
        ],
      ),
    );
  }
}
