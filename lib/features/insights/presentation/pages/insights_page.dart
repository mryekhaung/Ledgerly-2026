import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/insights/presentation/providers/insights_providers.dart';
import 'package:ledgerly/features/insights/presentation/widgets/cash_flow_line_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/donut_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/income_expense_bar_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/insight_period_switcher.dart';
import 'package:ledgerly/features/insights/presentation/widgets/insight_summary_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/top_categories_card.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:material_ui/material_ui.dart';

/// The Insights and Financial Analytics page (Phase 2).
///
/// Implements responsive 1 → 2 → 3 column grid per docs/Platform.md §2:
/// - Compact (< 600): Single scrolling column.
/// - Medium / Expanded (600–1199): 2-column card grid.
/// - Large (≥ 1200): 3-column card grid capped at 1200 px.
class InsightsPage extends ConsumerWidget {
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

                  return _ResponsiveInsightsContent(
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

class _ResponsiveInsightsContent extends StatelessWidget {
  const _ResponsiveInsightsContent({
    required this.insights,
    required this.currency,
  });

  final PeriodInsights insights;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 1200) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: _ThreeColumnLayout(insights: insights, currency: currency),
            ),
          );
        } else if (width >= 600) {
          return _TwoColumnLayout(insights: insights, currency: currency);
        } else {
          return _SingleColumnLayout(insights: insights, currency: currency);
        }
      },
    );
  }
}

class _SingleColumnLayout extends StatelessWidget {
  const _SingleColumnLayout({required this.insights, required this.currency});

  final PeriodInsights insights;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: <Widget>[
        InsightSummaryCard(
          summary: insights.summary,
          comparison: insights.comparison,
          currency: currency,
        ),
        const SizedBox(height: AppSpacing.md),
        DonutChartCard(
          breakdowns: insights.categoryBreakdowns,
          totalExpenseMinor: insights.summary.expenseMinor,
          currency: currency,
        ),
        const SizedBox(height: AppSpacing.md),
        IncomeExpenseBarChartCard(
          trendPoints: insights.trendPoints,
          currency: currency,
        ),
        const SizedBox(height: AppSpacing.md),
        CashFlowLineChartCard(
          trendPoints: insights.trendPoints,
          currency: currency,
        ),
        const SizedBox(height: AppSpacing.md),
        TopCategoriesCard(
          breakdowns: insights.categoryBreakdowns,
          currency: currency,
        ),
      ],
    );
  }
}

class _TwoColumnLayout extends StatelessWidget {
  const _TwoColumnLayout({required this.insights, required this.currency});

  final PeriodInsights insights;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                InsightSummaryCard(
                  summary: insights.summary,
                  comparison: insights.comparison,
                  currency: currency,
                ),
                const SizedBox(height: AppSpacing.md),
                DonutChartCard(
                  breakdowns: insights.categoryBreakdowns,
                  totalExpenseMinor: insights.summary.expenseMinor,
                  currency: currency,
                ),
                const SizedBox(height: AppSpacing.md),
                TopCategoriesCard(
                  breakdowns: insights.categoryBreakdowns,
                  currency: currency,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              children: <Widget>[
                IncomeExpenseBarChartCard(
                  trendPoints: insights.trendPoints,
                  currency: currency,
                ),
                const SizedBox(height: AppSpacing.md),
                CashFlowLineChartCard(
                  trendPoints: insights.trendPoints,
                  currency: currency,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeColumnLayout extends StatelessWidget {
  const _ThreeColumnLayout({required this.insights, required this.currency});

  final PeriodInsights insights;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                InsightSummaryCard(
                  summary: insights.summary,
                  comparison: insights.comparison,
                  currency: currency,
                ),
                const SizedBox(height: AppSpacing.md),
                TopCategoriesCard(
                  breakdowns: insights.categoryBreakdowns,
                  currency: currency,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: DonutChartCard(
              breakdowns: insights.categoryBreakdowns,
              totalExpenseMinor: insights.summary.expenseMinor,
              currency: currency,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              children: <Widget>[
                IncomeExpenseBarChartCard(
                  trendPoints: insights.trendPoints,
                  currency: currency,
                ),
                const SizedBox(height: AppSpacing.md),
                CashFlowLineChartCard(
                  trendPoints: insights.trendPoints,
                  currency: currency,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
