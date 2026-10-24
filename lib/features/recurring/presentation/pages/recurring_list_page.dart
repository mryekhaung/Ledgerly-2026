import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveAppBarAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_floating_action_button.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
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
    final strings = AppStrings.of(context);

    final activeItems = ref.watch(activeRecurringListProvider);
    final pausedItems = ref.watch(pausedRecurringListProvider);
    final dueItems = ref.watch(dueRecurringListProvider);
    final schedulerState = ref.watch(recurringSchedulerNotifierProvider);

    final displayedItems = _selectedTabIndex == 0 ? activeItems : pausedItems;

    return AppScaffold(
      title: strings('recurringTitle'),
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
            icon: const Icon(AppIcons.sync),
            tooltip: strings('recurringProcessNow'),
            onPressed: () => _runScheduler(context),
          ),
      ],
      adaptiveActions: <AdaptiveAppBarAction>[
        AdaptiveAppBarAction(
          iosSymbol: 'arrow.clockwise',
          icon: AppIcons.sync,
          label: strings('recurringProcessNow'),
          onPressed: () async {
            if (schedulerState.isProcessing) return;
            await _runScheduler(context);
          },
        ),
      ],
      floatingActionButton: displayedItems.isNotEmpty
          ? AppFloatingActionButton(
              onPressed: () => context.push(AppRoutes.recurringNew),
              icon: AppIcons.add,
              label: strings('recurringNew'),
              extended: true,
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
            child: SegmentedTabs<int>(
              tabs: <SegmentedTab<int>>[
                SegmentedTab<int>(
                  value: 0,
                  label: AppStrings.fill(context, 'recurringActiveTab', {
                    'count': activeItems.length,
                  }),
                  icon: AppIcons.success,
                ),
                SegmentedTab<int>(
                  value: 1,
                  label: AppStrings.fill(context, 'recurringPausedTab', {
                    'count': pausedItems.length,
                  }),
                  icon: AppIcons.pauseCircle,
                ),
              ],
              selected: _selectedTabIndex,
              onChanged: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Empty state
          if (displayedItems.isEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            StatePlaceholder(
              icon: AppIcons.recurring,
              title: strings('recurringEmptyTitle'),
              body: strings('recurringEmptyBody'),
              action: FilledButton.tonalIcon(
                onPressed: () => context.push(AppRoutes.recurringNew),
                icon: const Icon(AppIcons.add),
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

  Future<void> _runScheduler(BuildContext context) async {
    final result = await ref
        .read(recurringSchedulerNotifierProvider.notifier)
        .runScheduler();
    if (context.mounted) {
      AppFeedback.confirm(
        context,
        message: AppStrings.fill(context, 'recurringProcessedSuccess', {
          'count': result.generatedCount,
        }),
      );
    }
  }
}
