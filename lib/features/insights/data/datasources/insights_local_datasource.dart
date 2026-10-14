import 'dart:async';

import 'package:ledgerly/core/database/app_database.dart' as db;
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/data/mappers/category_mapper.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/insights/domain/entities/category_breakdown.dart';
import 'package:ledgerly/features/insights/domain/entities/daily_trend_point.dart';
import 'package:ledgerly/features/insights/domain/entities/period_comparison.dart';
import 'package:ledgerly/features/insights/domain/entities/period_insights.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';

/// Local SQLite data source for period-based insights and aggregations.
///
/// Follows ADR #1 and Architecture §7: SQL GROUP BY computes totals,
/// and periods are determined via [BudgetPeriod].
class InsightsLocalDataSource {
  const InsightsLocalDataSource(this._database);

  final db.AppDatabase _database;

  /// Reactive stream of insights for [period], compared against [previousPeriod].
  Stream<PeriodInsights> watchPeriodInsights({
    required BudgetPeriod period,
    required BudgetPeriod previousPeriod,
    required CurrencyCode currency,
  }) {
    // We watch transactionsDao.watchPeriodCategoryTotals(period).
    // In Drift, any change to transactions emits a new event.
    return _database.transactionsDao.watchPeriodCategoryTotals(period).asyncMap(
      (categoryRows) async {
        // 1. Fetch current daily totals from SQL
        final dailyTotals = await _database.transactionsDao
            .watchPeriodDailyTotals(period)
            .first;

        final currentIncome = await _database.transactionsDao.sumForPeriod(
          period,
          'income',
        );
        final currentExpense = await _database.transactionsDao.sumForPeriod(
          period,
          'expense',
        );

        // 2. Fetch previous period totals from SQL
        final prevIncome = await _database.transactionsDao.sumForPeriod(
          previousPeriod,
          'income',
        );
        final prevExpense = await _database.transactionsDao.sumForPeriod(
          previousPeriod,
          'expense',
        );

        final currentSummary = PeriodTotal(
          period: period,
          incomeMinor: currentIncome,
          expenseMinor: currentExpense,
          currency: currency,
        );

        final prevSummary = PeriodTotal(
          period: previousPeriod,
          incomeMinor: prevIncome,
          expenseMinor: prevExpense,
          currency: currency,
        );

        final comparison = PeriodComparison(
          current: currentSummary,
          previous: prevSummary,
        );

        // 3. Resolve categories for category breakdowns
        final categoryEntities = await _database.categoriesDao
            .watchAll()
            .first
            .then(CategoryMapper.toEntities);

        final categoryMap = <String, Category>{
          for (final cat in categoryEntities) cat.id: cat,
        };

        final breakdowns = <CategoryBreakdown>[];
        for (final row in categoryRows) {
          if (row.direction != 'expense' || row.totalMinor <= 0) continue;

          final category =
              categoryMap[row.categoryId] ??
              Category(
                id: row.categoryId,
                name: 'Other',
                iconKey: 'category',
                colorValue: 0xFF9E9E9E,
                kind: CategoryKind.expense,
                sortOrder: 999,
                isArchived: false,
                isDefault: false,
                createdAt: 0,
                updatedAt: 0,
              );

          final percentage = currentExpense > 0
              ? (row.totalMinor / currentExpense)
              : 0.0;

          breakdowns.add(
            CategoryBreakdown(
              category: category,
              amountMinor: row.totalMinor,
              percentage: percentage,
              currency: currency,
            ),
          );
        }

        breakdowns.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

        // 4. Build continuous daily trend points across the entire period
        final dailyMap = <LocalDate, ({int income, int expense})>{
          for (final row in dailyTotals)
            row.date: (income: row.incomeMinor, expense: row.expenseMinor),
        };

        final trendPoints = <DailyTrendPoint>[];
        var runningCumulativeNet = 0;

        for (var i = 0; i < period.length; i++) {
          final day = period.start.addDays(i)!;
          final entry = dailyMap[day];
          final dayIncome = entry?.income ?? 0;
          final dayExpense = entry?.expense ?? 0;
          final dayNet = dayIncome - dayExpense;
          runningCumulativeNet += dayNet;

          trendPoints.add(
            DailyTrendPoint(
              date: day,
              incomeMinor: dayIncome,
              expenseMinor: dayExpense,
              cumulativeNetMinor: runningCumulativeNet,
              currency: currency,
            ),
          );
        }

        return PeriodInsights(
          period: period,
          summary: currentSummary,
          comparison: comparison,
          categoryBreakdowns: breakdowns,
          trendPoints: trendPoints,
        );
      },
    );
  }
}
