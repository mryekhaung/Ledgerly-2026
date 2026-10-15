import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/insights/presentation/widgets/cash_flow_line_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/donut_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/income_expense_bar_chart_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/insight_summary_card.dart';
import 'package:ledgerly/features/insights/presentation/widgets/top_categories_card.dart';
import 'package:material_ui/material_ui.dart';

/// Compact single scrolling column.
///
/// Extracted from `insights_page.dart` (`docs/Conventions.md` §1).
class SingleColumnLayout extends StatelessWidget {
  /// Creates a [SingleColumnLayout].
  const SingleColumnLayout({
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
