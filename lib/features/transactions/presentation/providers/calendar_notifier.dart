import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/period/period_calculator.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';

/// The calendar page's mutable state: which period and day are visible.
///
/// Pure Dart so the period-arithmetic and day-selection logic is unit-testable
/// without a widget tree (`docs/Agent.md` §6).
final class CalendarState {
  /// Creates calendar state.
  CalendarState({
    BudgetPeriod? visiblePeriod,
    LocalDate? visibleMonth,
    required this.selectedDay,
    required this.isTodaySelected,
    PeriodCalculator? calculator,
  }) : visibleMonth =
           visibleMonth ??
           (visiblePeriod != null
               ? visiblePeriod.start
               : (calculator ?? PeriodCalculator(1))
                     .containing(selectedDay)
                     .start),
       visiblePeriod =
           visiblePeriod ??
           (calculator ?? PeriodCalculator(1)).containing(
             visibleMonth ?? selectedDay,
           );

  /// The month being browsed (backward compatibility).
  final LocalDate visibleMonth;

  /// The budget period being browsed.
  final BudgetPeriod visiblePeriod;

  /// The day the user has selected. Always inside [visiblePeriod] unless the
  /// user just switched period, in which case it is clamped into the new period.
  final LocalDate selectedDay;

  /// True when [selectedDay] is the current calendar day. Used to show/hide
  /// the "today" button.
  final bool isTodaySelected;

  /// The month before [visibleMonth], or null when the year would go below 1.
  LocalDate? get previousMonth => visibleMonth.addMonths(-1);

  /// The month after [visibleMonth], or null when the year would go above 9999.
  LocalDate? get nextMonth => visibleMonth.addMonths(1);

  /// True when the visible period does not contain today or today is not selected.
  bool get canGoToToday =>
      !isTodaySelected ||
      !visiblePeriod.contains(LocalDate.fromDateTime(DateTime.now()));

  /// Returns a state shifted to [period], keeping the selected day clamped.
  CalendarState withPeriod(BudgetPeriod period) {
    final candidateDay1 = _clampDay(period.start, selectedDay.day);
    final candidateDay2 = _clampDay(period.end, selectedDay.day);
    final LocalDate clampedDay;
    if (period.contains(candidateDay1)) {
      clampedDay = candidateDay1;
    } else if (period.contains(candidateDay2)) {
      clampedDay = candidateDay2;
    } else {
      clampedDay = _clampToPeriod(period, selectedDay);
    }
    return CalendarState(
      visibleMonth: period.start,
      visiblePeriod: period,
      selectedDay: clampedDay,
      isTodaySelected: _isToday(clampedDay),
    );
  }

  /// Returns a state shifted to [month], keeping the selected day clamped.
  CalendarState withMonth(LocalDate month, {PeriodCalculator? calculator}) {
    final calc = calculator ?? PeriodCalculator(1);
    final period = calc.containing(
      LocalDate(month.year, month.month, calc.startDay),
    );
    final state = withPeriod(period);
    return CalendarState(
      visibleMonth: month,
      visiblePeriod: period,
      selectedDay: state.selectedDay,
      isTodaySelected: state.isTodaySelected,
    );
  }

  /// Returns a state with [day] selected, scrolling the period if needed.
  CalendarState withDay(LocalDate day, {PeriodCalculator? calculator}) {
    final calc = calculator ?? PeriodCalculator(1);
    final period = visiblePeriod.contains(day)
        ? visiblePeriod
        : calc.containing(day);
    return CalendarState(
      visibleMonth: visiblePeriod.contains(day)
          ? visibleMonth
          : day.firstDayOfMonth,
      visiblePeriod: period,
      selectedDay: day,
      isTodaySelected: _isToday(day),
    );
  }

  /// Clamps [day] to the days actually in [month].
  static LocalDate _clampDay(LocalDate month, int day) {
    final maxDay = LocalDate.daysInMonth(month.year, month.month);
    return LocalDate(month.year, month.month, day > maxDay ? maxDay : day);
  }

  static LocalDate _clampToPeriod(BudgetPeriod period, LocalDate day) {
    if (day.isBefore(period.start)) return period.start;
    if (day.isAfter(period.end)) return period.end;
    return day;
  }

  static bool _isToday(LocalDate day) =>
      day.value == LocalDate.fromDateTime(DateTime.now()).value;
}

/// Drives the calendar page.
///
/// Holds the visible period and selected day; the streams for transactions,
/// daily totals, and day totals are derived from this state via
/// `ref.watch` in the page.
class CalendarNotifier extends Notifier<CalendarState> {
  @override
  CalendarState build() {
    final calculator = ref.watch(periodCalculatorProvider);
    final today = LocalDate.fromDateTime(DateTime.now());
    return CalendarState(
      visiblePeriod: calculator.containing(today),
      selectedDay: today,
      isTodaySelected: true,
    );
  }

  /// Shifts the visible period by [delta] periods.
  void shiftPeriod(int delta) {
    final calculator = ref.read(periodCalculatorProvider);
    var p = state.visiblePeriod;
    if (delta > 0) {
      for (var i = 0; i < delta; i++) {
        p = calculator.next(p);
      }
    } else if (delta < 0) {
      for (var i = 0; i < -delta; i++) {
        p = calculator.previous(p);
      }
    }
    state = state.withPeriod(p);
  }

  /// Shifts the visible month/period by [delta].
  void shiftMonth(int delta) => shiftPeriod(delta);

  /// Jumps straight to [period].
  void jumpToPeriod(BudgetPeriod period) => state = state.withPeriod(period);

  /// Jumps straight to the period containing [month].
  void jumpToMonth(LocalDate month) {
    final calculator = ref.read(periodCalculatorProvider);
    state = state.withPeriod(calculator.containing(month));
  }

  /// Selects a specific day, scrolling the period if needed.
  void selectDay(LocalDate day) {
    final calculator = ref.read(periodCalculatorProvider);
    state = state.withDay(day, calculator: calculator);
  }

  /// Jumps to today.
  void goToToday() {
    final calculator = ref.read(periodCalculatorProvider);
    final today = LocalDate.fromDateTime(DateTime.now());
    state = CalendarState(
      visiblePeriod: calculator.containing(today),
      selectedDay: today,
      isTodaySelected: true,
    );
  }
}

/// Provides the calendar state.
///
/// `autoDispose`: the calendar is not a global singleton — it owns transient
/// UI state (selected day) that should not leak across sessions.
final calendarProvider =
    NotifierProvider.autoDispose<CalendarNotifier, CalendarState>(
      CalendarNotifier.new,
    );

/// Derived: the stream of transactions for the selected day.
///
/// Kept as a separate provider so the day list rebuilds independently of the
/// grid and summary card.
final selectedDayTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
      final day = ref.watch(calendarProvider).selectedDay;
      final stream = ref.watch(watchDayTransactionsProvider).call((date: day));
      return stream.map(
        (result) => result.fold(
          onSuccess: (list) => list,
          onErr: (_) => const <Transaction>[],
        ),
      );
    });

/// Derived: the stream of daily totals for the visible period.
///
/// Used by the grid to paint the capsule intensities.
final monthDailyTotalsProvider = StreamProvider.autoDispose<List<DailyTotal>>((
  ref,
) {
  final period = ref.watch(calendarProvider).visiblePeriod;
  final currency = ref.watch(currencyProvider);
  final stream = ref.watch(watchPeriodDailyTotalsProvider).call((
    period: period,
    currency: currency,
  ));
  return stream.map(
    (result) => result.fold(
      onSuccess: (list) => list,
      onErr: (_) => const <DailyTotal>[],
    ),
  );
});

/// Derived: the selected **day's** headline figures — the summary card.
///
/// Deliberately a *day* total, not the period total: the card sits directly under
/// the grid and follows the highlighted day, so a period figure there would
/// answer a question the user did not ask. `WatchPeriodTotal` stays in the domain
/// for the Insights phase, but this screen does not need it — and an unwatched
/// provider would still open a Drift stream, so it is not declared here.
final selectedDayTotalProvider = StreamProvider.autoDispose<DailyTotal>((ref) {
  final day = ref.watch(calendarProvider).selectedDay;
  final currency = ref.watch(currencyProvider);
  final stream = ref.watch(watchDayTotalProvider).call((
    date: day,
    currency: currency,
  ));
  return stream.map(
    (result) => result.fold(
      onSuccess: (total) => total,
      onErr: (_) => DailyTotal.empty(day, currency),
    ),
  );
});
