import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/utils/month_grid_layout.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:ledgerly/features/transactions/presentation/providers/calendar_notifier.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/calendar/day_cell.dart';
import 'package:material_ui/material_ui.dart';

/// The month grid with day capsules.
///
/// Watches `monthDailyTotalsProvider` so the capsule intensities update when
/// transactions change, without rebuilding the whole page.
///
/// Extracted from `calendar_page.dart` (`docs/Conventions.md` §1).
class CalendarGrid extends ConsumerWidget {
  /// Creates a [CalendarGrid].
  const CalendarGrid({
    required this.period,
    required this.selectedDay,
    required this.weekStart,
    required this.isPayCycle,
    required this.onSelectDay,
    super.key,
  });

  /// The visible budget period.
  final BudgetPeriod period;

  /// The selected day.
  final LocalDate selectedDay;

  /// Which day opens the week.
  final GridWeekStart weekStart;

  /// Whether the period is a pay-cycle range.
  final bool isPayCycle;

  /// Called when a day is tapped.
  final ValueChanged<LocalDate> onSelectDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(monthDailyTotalsProvider);
    final totals = totalsAsync.value ?? const <DailyTotal>[];

    return MonthGrid(
      period: period,
      selectedDay: selectedDay,
      weekStart: weekStart,
      isPayCycle: isPayCycle,
      totals: totals,
      onSelectDay: onSelectDay,
    );
  }
}

/// The grid widget itself, separated so it can be unit-tested with fake data.
class MonthGrid extends StatelessWidget {
  /// Creates a [MonthGrid].
  const MonthGrid({
    required this.period,
    required this.selectedDay,
    required this.weekStart,
    this.isPayCycle = false,
    required this.totals,
    required this.onSelectDay,
    super.key,
  });

  /// The visible budget period.
  final BudgetPeriod period;

  /// The selected day.
  final LocalDate selectedDay;

  /// Which day opens the week.
  final GridWeekStart weekStart;

  /// Whether the period is a pay-cycle range.
  final bool isPayCycle;

  /// Per-day aggregates feeding the capsule intensities.
  final List<DailyTotal> totals;

  /// Called when a day is tapped.
  final ValueChanged<LocalDate> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final cells = MonthGridLayout.periodCells(period, weekStart: weekStart);
    final rowCount = cells.length ~/ MonthGridLayout.daysPerWeek;
    final today = LocalDate.fromDateTime(DateTime.now());
    final intensities = _intensities(totals);

    return Column(
      children: <Widget>[
        for (var row = 0; row < rowCount; row++)
          LayoutBuilder(
            builder: (context, constraints) =>
                // Cell width drives the capsule's 60 % width (§6.2). Every cell
                // in a row shares one width because they are `Expanded`, so one
                // measurement per row is enough.
                Row(
                  children: <Widget>[
                    for (
                      var column = 0;
                      column < MonthGridLayout.daysPerWeek;
                      column++
                    )
                      Expanded(
                        child: switch (cells[row * MonthGridLayout.daysPerWeek +
                            column]) {
                          null => const SizedBox(height: 48),
                          final day => DayCell(
                            day: day,
                            cellWidth:
                                constraints.maxWidth /
                                MonthGridLayout.daysPerWeek,
                            showMonthLabel: isPayCycle && day.day == 1,
                            isSelected: day.value == selectedDay.value,
                            isToday: day.value == today.value,
                            intensity: intensities[day.value],
                            onTap: () => onSelectDay(day),
                          ),
                        },
                      ),
                  ],
                ),
          ),
      ],
    );
  }

  /// Maps each day's packed value to its capsule intensity.
  ///
  /// Intensity is the absolute net divided by the 95th-percentile absolute net
  /// of the month, clamped to [0, 1] and quantized to 5 steps
  /// (`docs/Design.md` §6.2).
  static Map<int, DayIntensity> _intensities(List<DailyTotal> totals) {
    if (totals.isEmpty) return const <int, DayIntensity>{};

    final nets =
        totals
            .where((t) => t.hasActivity)
            .map((t) => t.netMinor.abs())
            .toList(growable: false)
          ..sort();

    if (nets.isEmpty) return const <int, DayIntensity>{};

    final p95Index = ((nets.length - 1) * 0.95).round();
    final p95 = nets[p95Index];
    if (p95 == 0) return const <int, DayIntensity>{};

    return <int, DayIntensity>{
      for (final total in totals)
        if (total.hasActivity)
          total.date.value: DayIntensity.fromNet(
            total.netMinor,
            p95,
            total.dominantDirection,
          ),
    };
  }
}
