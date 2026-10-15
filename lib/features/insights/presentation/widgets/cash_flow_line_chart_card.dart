import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/features/insights/domain/entities/daily_trend_point.dart';
import 'package:material_ui/material_ui.dart';

/// Line chart showing the cumulative cash flow trend across the period days.
///
/// Wrapped in a [RepaintBoundary] per docs/Design.md §7.
class CashFlowLineChartCard extends StatelessWidget {
  const CashFlowLineChartCard({
    required this.trendPoints,
    required this.currency,
    super.key,
  });

  final List<DailyTrendPoint> trendPoints;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    if (trendPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final latestPoint = trendPoints.last;
    final latestMoney = Money.minor(latestPoint.cumulativeNetMinor, currency);

    // §5.2: chart cards are AppCards, not bespoke subtle containers.
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              Text(
                strings('insightsCashFlowTrend'),
                style: theme.textTheme.titleMedium,
              ),
              AmountText(latestMoney, style: AmountStyle.row, signed: true),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _CashFlowPainter(
                  points: trendPoints,
                  lineColor: latestPoint.cumulativeNetMinor >= 0
                      ? colors.moneyIn
                      : colors.moneyOut,
                  gridColor: colors.border,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${trendPoints.first.date.day}/${trendPoints.first.date.month}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                '${trendPoints.last.date.day}/${trendPoints.last.date.month}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashFlowPainter extends CustomPainter {
  const _CashFlowPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
  });

  final List<DailyTrendPoint> points;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    var minY = 0;
    var maxY = 0;
    for (final p in points) {
      if (p.cumulativeNetMinor < minY) minY = p.cumulativeNetMinor;
      if (p.cumulativeNetMinor > maxY) maxY = p.cumulativeNetMinor;
    }

    if (minY == maxY) {
      minY = -100;
      maxY = 100;
    }

    // Add 10% breathing room to top and bottom
    final range = (maxY - minY).toDouble();
    final paddedMin = minY - (range * 0.1);
    final paddedMax = maxY + (range * 0.1);
    final effectiveRange = paddedMax - paddedMin;

    double getY(int val) {
      final ratio = (val - paddedMin) / effectiveRange;
      return size.height - (ratio * size.height);
    }

    // Draw baseline (zero line)
    final zeroY = getY(0).clamp(0.0, size.height);
    final baselinePaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), baselinePaint);

    // Compute coordinate points
    final coordinates = <Offset>[];
    final dx = points.length > 1 ? size.width / (points.length - 1) : 0.0;

    for (var i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = getY(points[i].cumulativeNetMinor).clamp(0.0, size.height);
      coordinates.add(Offset(x, y));
    }

    // Build path with cubic bezier smoothing
    final path = Path();
    path.moveTo(coordinates.first.dx, coordinates.first.dy);

    for (var i = 0; i < coordinates.length - 1; i++) {
      final current = coordinates[i];
      final next = coordinates[i + 1];
      final controlPointX = (current.dx + next.dx) / 2;
      path.cubicTo(
        controlPointX,
        current.dy,
        controlPointX,
        next.dy,
        next.dx,
        next.dy,
      );
    }

    // Gradient fill under the curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, zeroY)
      ..lineTo(0, zeroY)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Draw endpoints
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(coordinates.last, 4.0, pointPaint);
  }

  @override
  bool shouldRepaint(_CashFlowPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;
    if (oldDelegate.lineColor != lineColor) return true;
    return oldDelegate.gridColor != gridColor;
  }
}
