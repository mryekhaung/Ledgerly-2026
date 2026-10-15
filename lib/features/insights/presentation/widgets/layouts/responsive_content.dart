import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/insights/presentation/widgets/layouts/single_column_layout.dart';
import 'package:ledgerly/features/insights/presentation/widgets/layouts/three_column_layout.dart';
import 'package:ledgerly/features/insights/presentation/widgets/layouts/two_column_layout.dart';
import 'package:material_ui/material_ui.dart';

/// Picks the card grid for the available width.
///
/// Extracted from `insights_page.dart` (`docs/Conventions.md` §1).
class ResponsiveInsightsContent extends StatelessWidget {
  /// Creates a [ResponsiveInsightsContent].
  const ResponsiveInsightsContent({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 1200) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ThreeColumnLayout(insights: insights, currency: currency),
            ),
          );
        } else if (width >= 600) {
          return TwoColumnLayout(insights: insights, currency: currency);
        } else {
          return SingleColumnLayout(insights: insights, currency: currency);
        }
      },
    );
  }
}
