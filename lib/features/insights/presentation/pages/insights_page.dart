import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/insights/presentation/providers/insights_providers.dart';
import 'package:ledgerly/features/insights/presentation/widgets/insight_period_switcher.dart';
import 'package:ledgerly/features/insights/presentation/widgets/layouts/responsive_content.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:material_ui/material_ui.dart';

/// The Insights and Financial Analytics page (Phase 2).
///
/// Implements responsive 1 → 2 → 3 column grid per docs/Platform.md §2:
/// - Compact (< 600): Single scrolling column.
/// - Medium / Expanded (600–1199): 2-column card grid.
/// - Large (≥ 1200): 3-column card grid capped at 1200 px.
///
/// Composition root only: layouts live in `widgets/layouts/`
/// (`docs/Conventions.md` §1).
class InsightsPage extends ConsumerWidget {
  /// Creates the page.
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final currentPeriod = ref.watch(insightsPeriodProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);
    final isPayCycle = monthStartDay != 1;
    final insightsAsync = ref.watch(insightsDataProvider);
    final currency = ref.watch(currencyProvider);

    return AppScaffold(
      title: strings('insightsTitle'),
      useSafeArea: false,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: InsightPeriodSwitcher(
                period: currentPeriod,
                isPayCycle: isPayCycle,
                onPrevious: () =>
                    ref.read(insightsPeriodProvider.notifier).previous(),
                onNext: () => ref.read(insightsPeriodProvider.notifier).next(),
              ),
            ),
            Divider(height: 1, color: AppThemeColors.of(context).border),
            Expanded(
              child: insightsAsync.when(
                loading: () => const LoadingPlaceholder(),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: ErrorBanner(
                      message: strings('stateErrorBody'),
                      onRetry: () => ref.invalidate(insightsDataProvider),
                    ),
                  ),
                ),
                data: (insights) {
                  if (insights.isEmpty) {
                    return StatePlaceholder(
                      icon: AppIcons.insights,
                      title: strings('insightsNoDataTitle'),
                      body: strings('insightsNoDataBody'),
                    );
                  }

                  return ResponsiveInsightsContent(
                    insights: insights,
                    currency: currency,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
