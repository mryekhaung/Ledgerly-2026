import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:ledgerly/features/recurring/presentation/widgets/recurring_item_card.dart';
import 'package:ledgerly/features/recurring/presentation/widgets/recurring_pending_banner.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:material_ui/material_ui.dart';

/// Main page displaying scheduled recurring transactions.
class RecurringListPage extends ConsumerStatefulWidget {
  const RecurringListPage({super.key});

  @override
  ConsumerState<RecurringListPage> createState() => _RecurringListPageState();
}

class _RecurringListPageState extends ConsumerState<RecurringListPage> {
  int _selectedTabIndex = 0; // 0 = Active, 1 = Paused

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    final activeItems = ref.watch(activeRecurringListProvider);
    final pausedItems = ref.watch(pausedRecurringListProvider);
    final dueItems = ref.watch(dueRecurringListProvider);
    final schedulerState = ref.watch(recurringSchedulerNotifierProvider);

    final displayedItems = _selectedTabIndex == 0 ? activeItems : pausedItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings('recurringTitle')),
        actions: <Widget>[
          if (schedulerState.isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: strings('recurringProcessNow'),
              onPressed: () async {
                final result = await ref
                    .read(recurringSchedulerNotifierProvider.notifier)
                    .runScheduler();
                if (context.mounted) {
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
            ),
        ],
      ),
      floatingActionButton: displayedItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.recurringNew),
              icon: const Icon(Icons.add),
              label: Text(strings('recurringNew')),
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
          // Pending banner if any items need confirmation
          RecurringPendingBanner(
            pendingItems: dueItems.where((t) => !t.autoAdd).toList(),
          ),

          // Tabs: Active vs Paused
          Center(
            child: SegmentedButton<int>(
              segments: <ButtonSegment<int>>[
                ButtonSegment<int>(
                  value: 0,
                  label: Text('Active (${activeItems.length})'),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('Paused (${pausedItems.length})'),
                  icon: const Icon(Icons.pause_circle_outline, size: 16),
                ),
              ],
              selected: {_selectedTabIndex},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedTabIndex = selection.first;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Empty state
          if (displayedItems.isEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            StatePlaceholder(
              icon: Icons.event_repeat,
              title: strings('recurringEmptyTitle'),
              body: strings('recurringEmptyBody'),
              action: FilledButton.tonalIcon(
                onPressed: () => context.push(AppRoutes.recurringNew),
                icon: const Icon(Icons.add),
                label: Text(strings('recurringNew')),
              ),
            ),
          ] else ...<Widget>[
            // Recurring item cards
            for (final item in displayedItems)
              RecurringItemCard(key: ValueKey(item.id), item: item),
          ],
          const SizedBox(height: 80), // Fab spacing
        ],
      ),
    );
  }
}
