import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/app_dialog.dart';
import 'package:ledgerly/core/widgets/app_overflow_menu.dart';
import 'package:ledgerly/core/widgets/capped_row.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:material_ui/material_ui.dart';

/// Card item representing a scheduled recurring transaction rule.
class RecurringItemCard extends ConsumerWidget {
  const RecurringItemCard({required this.item, super.key});

  final RecurringTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final category = ref.watch(categoryByIdProvider(item.categoryId)).value;

    final today = LocalDate.fromDateTime(DateTime.now());
    final isDue = item.isDue(today);
    final isTomorrow = item.nextDueDate == today.addDays(1);

    final frequencyLabel = switch (item.frequency) {
      RecurringFrequency.daily => strings('recurringFrequencyDaily'),
      RecurringFrequency.weekly => strings('recurringFrequencyWeekly'),
      RecurringFrequency.monthly => strings('recurringFrequencyMonthly'),
      RecurringFrequency.yearly => strings('recurringFrequencyYearly'),
    };

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      border: Border.all(
        color: isDue
            ? colors.warning.withValues(alpha: 0.6)
            : colors.border.withValues(alpha: 0.4),
        width: isDue ? 1.5 : 1.0,
      ),
      onTap: () => context.pushNamed(
        AppRoutes.recurringEditName,
        pathParameters: {'id': item.id},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CappedRow(
            builder: (context, trailingMaxWidth) => Row(
              children: <Widget>[
                CategoryGem(
                  colorValue: category?.colorValue ?? 0xFF888888,
                  iconKey: category?.iconKey,
                  size: CategoryGemSize.md,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        category?.name ?? strings('budgetsCategory'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.note != null &&
                          item.note!.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          item.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Capped rather than flexible: the amount would push the row over
                // at 2× type (`docs/Design.md` §8), but a flex share would also
                // bind at 1× and truncate it on a screen that has room. See
                // `CappedRow`.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: trailingMaxWidth),
                  child: AmountText(
                    item.amount,
                    style: AmountStyle.row,
                    signed: true,
                    color: item.direction == TransactionDirection.income
                        ? colors.moneyIn
                        : colors.moneyOut,
                  ),
                ),
                AppOverflowMenu<String>(
                  icon: AppIcons.more,
                  cancelLabel: strings('actionCancel'),
                  onSelected: (value) =>
                      unawaited(_handleMenuAction(context, ref, value)),
                  items: <OverflowMenuItem<String>>[
                    OverflowMenuItem<String>(
                      value: 'skip',
                      label: strings('recurringActionSkip'),
                      icon: AppIcons.skipNext,
                    ),
                    OverflowMenuItem<String>(
                      value: 'pause',
                      label: item.isArchived
                          ? strings('recurringActionResume')
                          : strings('recurringActionPause'),
                      icon: item.isArchived ? AppIcons.play : AppIcons.pause,
                    ),
                    OverflowMenuItem<String>(
                      value: 'edit',
                      label: strings('budgetsEdit'),
                      icon: AppIcons.edit,
                    ),
                    OverflowMenuItem<String>(
                      value: 'delete',
                      label: strings('recurringActionDelete'),
                      icon: AppIcons.destructive,
                      destructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              // Frequency badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  frequencyLabel,
                  style: AppTypography.caption.copyWith(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Auto vs Manual chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (item.autoAdd ? colors.moneyIn : colors.textSecondary)
                      .withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  item.autoAdd ? 'Auto' : 'Manual',
                  style: AppTypography.caption.copyWith(
                    color: item.autoAdd ? colors.moneyIn : colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Due indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDue
                      ? colors.warning.withValues(alpha: 0.15)
                      : colors.surface,
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(
                    color: isDue
                        ? colors.warning
                        : colors.border.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  isDue
                      ? strings('recurringDueToday')
                      : (isTomorrow
                            ? strings('recurringDueTomorrow')
                            : '${item.nextDueDate}'),
                  style: AppTypography.caption.copyWith(
                    color: isDue ? colors.warning : colors.textSecondary,
                    fontWeight: isDue ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    final strings = AppStrings.of(context);
    final scheduler = ref.read(recurringSchedulerNotifierProvider.notifier);
    switch (value) {
      case 'skip':
        await scheduler.skipOccurrence(item.id);
        if (context.mounted) {
          AppFeedback.confirm(
            context,
            message: strings('recurringSkippedSuccess'),
          );
        }
      case 'pause':
        await scheduler.setArchived(item.id, !item.isArchived);
      case 'edit':
        if (context.mounted) {
          unawaited(
            context.pushNamed(
              AppRoutes.recurringEditName,
              pathParameters: {'id': item.id},
            ),
          );
        }
      case 'delete':
        final confirm = await AppDialog.confirm(
          context: context,
          title: strings('recurringConfirmDelete'),
          message: strings('recurringConfirmDeleteMessage'),
          confirmLabel: strings('actionDelete'),
          cancelLabel: strings('actionCancel'),
          isDestructive: true,
        );
        if (confirm == true) {
          await scheduler.delete(item.id);
          if (context.mounted) {
            AppFeedback.confirm(
              context,
              message: strings('recurringDeletedSuccess'),
            );
          }
        }
    }
  }
}
