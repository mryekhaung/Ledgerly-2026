import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/insights/presentation/widgets/cash_flow_line_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/donut_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/income_expense_bar_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/insight_summary_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/top_categories_card.dart';
import 'package:material_ui/material_ui.dart';

/// Medium/expanded two-column card grid.
///
/// Extracted from `insights_page.dart` (`docs/Conventions.md` §1).
class TwoColumnLayout extends StatelessWidget {
  /// Creates a [TwoColumnLayout].
  const TwoColumnLayout({
    required this.insights,
    required this.currency,
    super.key,
  });

  /// The period insights to render.
  final PeriodInsights insights;

  /// The display currency.
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
