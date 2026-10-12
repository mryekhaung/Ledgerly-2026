import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:ledgerly/features/transactions/domain/usecases/watch_transactions.dart'
    as watch;
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';

/// The calendar page's mutable state: which month and day are visible.
///
/// Pure Dart so the month-arithmetic and day-selection logic is unit-testable
/// without a widget tree (`docs/Agent.md` §6).
final class CalendarState {
  /// Creates calendar state.
  const CalendarState({
    required this.visibleMonth,
    required this.selectedDay,
    required this.isTodaySelected,
  });

  /// The month being browsed, normalised to its first day.
  final LocalDate visibleMonth;

  /// The day the user has selected. Always inside [visibleMonth] unless the
  /// user just switched month, in which case it is the same day-of-month
  /// clamped to the new month (so 31 March → 30 April, not 30 April → 29).
  final LocalDate selectedDay;

  /// True when [selectedDay] is the current calendar day. Used to show/hide
  /// the "today" button.
  final bool isTodaySelected;

  /// The month before [visibleMonth], or null when the year would go below 1.
  LocalDate? get previousMonth => visibleMonth.addMonths(-1);

  /// The month after [visibleMonth], or null when the year would go above 9999.
  LocalDate? get nextMonth => visibleMonth.addMonths(1);

  /// True when the visible month is not the current month.
  bool get canGoToToday =>
      !isTodaySelected ||
      visibleMonth.value !=
          LocalDate.fromDateTime(DateTime.now()).firstDayOfMonth.value;

  /// Returns a state shifted to [month], keeping the selected day clamped.
  CalendarState withMonth(LocalDate month) {
    final clampedDay = _clampDay(month, selectedDay.day);
    return CalendarState(
      visibleMonth: month,
      selectedDay: clampedDay,
      isTodaySelected: _isToday(clampedDay),
    );
  }

  /// Returns a state with [day] selected.
  CalendarState withDay(LocalDate day) => CalendarState(
    visibleMonth: day.firstDayOfMonth,
    selectedDay: day,
    isTodaySelected: _isToday(day),
  );

  /// Clamps [day] to the days actually in [month].
  static LocalDate _clampDay(LocalDate month, int day) {
    final maxDay = LocalDate.daysInMonth(month.year, month.month);
    return LocalDate(month.year, month.month, day > maxDay ? maxDay : day);
  }

  static bool _isToday(LocalDate day) =>
      day.value == LocalDate.fromDateTime(DateTime.now()).value;
}

/// Drives the calendar page.
///
/// Holds the visible month and selected day; the streams for transactions,
/// daily totals, and month totals are derived from this state via
/// `ref.watch` in the page.
class CalendarNotifier extends Notifier<CalendarState> {
  @override
  CalendarState build() {
    final today = LocalDate.fromDateTime(DateTime.now());
    return CalendarState(
      visibleMonth: today.firstDayOfMonth,
      selectedDay: today,
      isTodaySelected: true,
    );
  }

  /// Shifts the visible month by [delta] months.
  void shiftMonth(int delta) {
    final next = state.visibleMonth.addMonths(delta);
    if (next == null) return;
    state = state.withMonth(next);
  }

  /// Jumps straight to [month], from the month/year picker.
  ///
  /// Normalises to the first day because the round-trip through the picker is
  /// not guaranteed to preserve it, and the calendar's invariant is that
  /// `visibleMonth` is always a month's first day.
  ///
  /// The selected day follows via [CalendarState.withMonth], which clamps it
  /// into the new month — so jumping from 31 March to February lands on the
  /// 28th/29th rather than throwing.
  void jumpToMonth(LocalDate month) => state = state.withMonth(
    month.firstDayOfMonth,
  );

  /// Selects a specific day, scrolling the month if needed.
  void selectDay(LocalDate day) => state = state.withDay(day);

  /// Jumps to today.
  void goToToday() =>
      state = state.withDay(LocalDate.fromDateTime(DateTime.now()));
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

/// Derived: the stream of daily totals for the visible month.
///
/// Used by the grid to paint the capsule intensities.
final monthDailyTotalsProvider = StreamProvider.autoDispose<List<DailyTotal>>((
  ref,
) {
  final month = ref.watch(calendarProvider).visibleMonth;
  final currency = ref.watch(currencyProvider);
  final stream = ref.watch(watchMonthDailyTotalsProvider).call((
    month: month,
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
/// Deliberately a *day* total, not the month total: the card sits directly under
/// the grid and follows the highlighted day, so a month figure there would
/// answer a question the user did not ask. `WatchMonthTotal` stays in the domain
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
