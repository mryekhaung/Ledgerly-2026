import 'dart:math' as math;

import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/insights/domain/entities/category_breakdown.dart';
import 'package:material_ui/material_ui.dart';

/// Donut chart displaying spending distribution by category.
///
/// Wrapped in a [RepaintBoundary] per docs/Design.md §7: isolates canvas repaints.
class DonutChartCard extends StatelessWidget {
  const DonutChartCard({
    required this.breakdowns,
    required this.totalExpenseMinor,
    required this.currency,
    super.key,
  });

  final List<CategoryBreakdown> breakdowns;
  final int totalExpenseMinor;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    if (breakdowns.isEmpty || totalExpenseMinor == 0) {
      return const SizedBox.shrink();
    }

    final totalMoney = Money.minor(totalExpenseMinor, currency);

    // §5.2: chart cards are AppCards, not bespoke subtle containers.
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings('insightsSpendingByCategory'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    breakdowns: breakdowns,
                    backgroundColor: colors.border,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            strings('insightsTotalExpense'),
                            // Dropping the `fontSize: 10` override keeps the
                            // `caption` (11) the theme already applies — the §3
                            // floor.
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          AmountText(
                            totalMoney,
                            style: AmountStyle.row,
                            signed: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: breakdowns.take(6).map((item) {
              final pct = (item.percentage * 100).toStringAsFixed(0);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: colors.border, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CategoryGem(
                      colorValue: item.category.colorValue,
                      iconKey: item.category.iconKey,
                      size: CategoryGemSize.sm,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // The legend chip sits in a `Wrap`, so it can only be as
                    // wide as the card. A long category name at 2× type
                    // (`docs/Design.md` §8) has to give way.
                    Flexible(
                      child: Text(
                        item.category.name,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$pct%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.breakdowns,
    required this.backgroundColor,
  });

  final List<CategoryBreakdown> breakdowns;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.16;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = backgroundColor.withValues(alpha: 0.3);
    canvas.drawArc(rect, 0, 2 * math.pi, false, bgPaint);

    var startAngle = -math.pi / 2;
    const gapAngle = 0.04; // gap between segments

    for (final item in breakdowns) {
      final sweepAngle = item.percentage * 2 * math.pi;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = Color(item.category.colorValue);

      final effectiveSweep = sweepAngle > gapAngle
          ? sweepAngle - gapAngle
          : sweepAngle;
      canvas.drawArc(
        rect,
        startAngle + (gapAngle / 2),
        effectiveSweep,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    if (oldDelegate.breakdowns.length != breakdowns.length) return true;
    for (var i = 0; i < breakdowns.length; i++) {
      if (oldDelegate.breakdowns[i] != breakdowns[i]) return true;
    }
    return oldDelegate.backgroundColor != backgroundColor;
  }
}
