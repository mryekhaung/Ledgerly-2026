import 'dart:math' as math;

import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/features/insights/domain/entities/daily_trend_point.dart';
import 'package:material_ui/material_ui.dart';

/// Bar chart comparing income vs expense grouped over the period.
///
/// Wrapped in a [RepaintBoundary] per docs/Design.md §7.
class IncomeExpenseBarChartCard extends StatelessWidget {
  const IncomeExpenseBarChartCard({
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

    // Group points into 4 weekly chunks for clear bar presentation
    const chunkCount = 4;
    final chunkSize = (trendPoints.length / chunkCount).ceil();
    final chunks = <({int income, int expense, String label})>[];

    for (var i = 0; i < chunkCount; i++) {
      final startIndex = i * chunkSize;
      if (startIndex >= trendPoints.length) break;
      final endIndex = math.min((i + 1) * chunkSize, trendPoints.length);
      final sub = trendPoints.sublist(startIndex, endIndex);

      final chunkIncome = sub.fold(0, (sum, p) => sum + p.incomeMinor);
      final chunkExpense = sub.fold(0, (sum, p) => sum + p.expenseMinor);
      final label = 'W${i + 1}';
      chunks.add((income: chunkIncome, expense: chunkExpense, label: label));
    }

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
                strings('insightsIncomeVsExpense'),
                style: theme.textTheme.titleMedium,
              ),
              // A `Wrap` rather than a `Row`: at 2× type (`docs/Design.md` §8)
              // the two legend dots cannot share a line with each other inside
              // the outer wrap's remaining width, so let them break instead of
              // overflowing. The labels are short, so each dot still fits.
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  _LegendDot(
                    color: colors.moneyIn,
                    label: strings('calendarIncome'),
                  ),
                  _LegendDot(
                    color: colors.moneyOut,
                    label: strings('calendarExpense'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 150,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BarChartPainter(
                  chunks: chunks,
                  incomeColor: colors.moneyIn,
                  expenseColor: colors.moneyOut,
                  gridColor: colors.border,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.chunks,
    required this.incomeColor,
    required this.expenseColor,
    required this.gridColor,
  });

  final List<({int income, int expense, String label})> chunks;
  final Color incomeColor;
  final Color expenseColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (chunks.isEmpty) return;

    var maxVal = 0;
    for (final c in chunks) {
      if (c.income > maxVal) maxVal = c.income;
      if (c.expense > maxVal) maxVal = c.expense;
    }
    if (maxVal == 0) maxVal = 100;

    final bottomAxisY = size.height - 20;
    final availableHeight = bottomAxisY - 10;

    // Draw baseline
    final axisPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, bottomAxisY),
      Offset(size.width, bottomAxisY),
      axisPaint,
    );

    final groupWidth = size.width / chunks.length;
    final barWidth = math.min(groupWidth * 0.28, 24.0);
    const barSpacing = 4.0;
    const cornerRadius = Radius.circular(4.0);

    final incomePaint = Paint()..color = incomeColor;
    final expensePaint = Paint()..color = expenseColor;

    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final groupCenterX = (i * groupWidth) + (groupWidth / 2);

      // Income bar
      final incomeHeight = (chunk.income / maxVal) * availableHeight;
      final incomeX = groupCenterX - barWidth - (barSpacing / 2);
      final incomeY = bottomAxisY - incomeHeight;
      if (incomeHeight > 0) {
        final incomeRRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(incomeX, incomeY, barWidth, incomeHeight),
          topLeft: cornerRadius,
          topRight: cornerRadius,
        );
        canvas.drawRRect(incomeRRect, incomePaint);
      }

      // Expense bar
      final expenseHeight = (chunk.expense / maxVal) * availableHeight;
      final expenseX = groupCenterX + (barSpacing / 2);
      final expenseY = bottomAxisY - expenseHeight;
      if (expenseHeight > 0) {
        final expenseRRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(expenseX, expenseY, barWidth, expenseHeight),
          topLeft: cornerRadius,
          topRight: cornerRadius,
        );
        canvas.drawRRect(expenseRRect, expensePaint);
      }

      // Label below bar. This is a CustomPainter, so there is no BuildContext
      // to read the TextTheme from — derive the metrics from `caption` (11),
      // the §3 floor, rather than a literal that can drift under it.
      final textSpan = TextSpan(
        text: chunk.label,
        style: AppTypography.caption.copyWith(color: gridColor),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(groupCenterX - (textPainter.width / 2), bottomAxisY + 4),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) {
    if (oldDelegate.chunks.length != chunks.length) return true;
    for (var i = 0; i < chunks.length; i++) {
      if (oldDelegate.chunks[i] != chunks[i]) return true;
    }
    return oldDelegate.incomeColor != incomeColor ||
        oldDelegate.expenseColor != expenseColor ||
        oldDelegate.gridColor != gridColor;
  }
}
