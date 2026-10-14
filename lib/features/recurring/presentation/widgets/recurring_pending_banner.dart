import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Banner displayed at the top of the recurring list or dashboard when there are
/// manual recurring items awaiting user confirmation.
class RecurringPendingBanner extends ConsumerWidget {
  const RecurringPendingBanner({required this.pendingItems, super.key});

  final List<RecurringTransaction> pendingItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pendingItems.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.notifications_active, color: colors.warning, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings('recurringPendingBannerTitle'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pendingItems.length} items awaiting confirmation',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () async {
              final result = await ref
                  .read(recurringSchedulerNotifierProvider.notifier)
                  .runScheduler();
              if (context.mounted && result.generatedCount > 0) {
                AppFeedback.confirm(
                  context,
                  message: AppStrings.fill(
                    context,
                    'recurringProcessedSuccess',
                    {'count': result.generatedCount},
                  ),
                );
              }
            },
            child: Text(strings('recurringPendingActionConfirm')),
          ),
        ],
      ),
    );
  }
}
