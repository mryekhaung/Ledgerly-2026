import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/utils/month_grid_layout.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/month_year_picker_page.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:ledgerly/features/transactions/presentation/providers/calendar_notifier.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/calendar/day_list.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/calendar/month_grid.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/calendar/month_swipe_area.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/calendar/month_switcher.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/calendar/summary_card.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/calendar/weekday_header.dart';
import 'package:material_ui/material_ui.dart';

/// The calendar / home page.
///
/// Compact: one scrolling column — month grid, summary card, day list.
/// Medium+: two panes — **left** the month grid and its summary, **right** the
/// selected day's transactions (docs/Platform.md §5). The split is mechanical
/// because the grid and the list were already separate widgets, and both panes
/// scroll independently on the wide layout so swiping the month never moves the
/// day list out of view.
///
/// The grid is Monday-first, with a capsule under each day encoding the net
/// spend magnitude. Tapping a day selects it; the summary card and day list
/// rebuild from the selection.
///
/// Composition root only: the grid, rows, cards and controls live in
/// `widgets/calendar/` (`docs/Conventions.md` §1).
class CalendarPage extends ConsumerWidget {
  /// Creates the calendar page.
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final state = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);
    final sizeClass = WindowSizeClass.of(context);
    // The grid's first column follows the user's week-start preference; the
    // settings enum is mapped here, where `features/transactions` meets
    // `features/settings`, so `core/utils` stays free of a feature import.
    final weekStart = switch (ref.watch(weekStartProvider)) {
      WeekStart.sunday => GridWeekStart.sunday,
      WeekStart.monday => GridWeekStart.monday,
    };

    // The month controls belong to the grid pane on both layouts, so they are
    // built once here rather than duplicated per branch.
    //
    // The swipe area wraps the switcher, the weekday header and the grid — but
    // deliberately *not* the summary card. The card reports the selected day, so
    // making it part of the horizontal gesture would let a swipe that clearly
    // reads as "the calendar moved" silently also change the figure below it.
    final monthStartDay = ref.watch(monthStartDayProvider);
    final isPayCycle = monthStartDay != 1;

    final monthPane = <Widget>[
      MonthSwipeArea(
        onPrevious: () => notifier.shiftMonth(-1),
        onNext: () => notifier.shiftMonth(1),
        child: Column(
          children: <Widget>[
            MonthSwitcher(
              period: state.visiblePeriod,
              isPayCycle: isPayCycle,
              onPrevious: () => notifier.shiftMonth(-1),
              onNext: () => notifier.shiftMonth(1),
              onPickMonth: () =>
                  _pickMonth(context, notifier, state.visiblePeriod.start),
            ),
            const SizedBox(height: AppSpacing.md),
            WeekdayHeader(weekStart: weekStart),
            const SizedBox(height: AppSpacing.sm),
            CalendarGrid(
              period: state.visiblePeriod,
              selectedDay: state.selectedDay,
              weekStart: weekStart,
              isPayCycle: isPayCycle,
              onSelectDay: notifier.selectDay,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      CalendarSummaryCard(day: state.selectedDay),
    ];

    return AppScaffold(
      title: strings('navigationCalendar'),
      actions: <Widget>[
        IconButton(
          icon: const Icon(AppIcons.search),
          tooltip: strings('transactionsTitle'),
          onPressed: () => context.push(AppRoutes.transactions),
        ),
        if (state.canGoToToday)
          TextButton(
            onPressed: notifier.goToToday,
            child: Text(strings('calendarToday')),
          ),
      ],
      body: sizeClass.isTwoPaneCapable
          ? _WideBody(
              monthPane: monthPane,
              dayPane: DayList(day: state.selectedDay),
            )
          : ListView(
              padding: ResponsiveInsets.pageHorizontal(context),
              children: <Widget>[
                ...monthPane,
                const SizedBox(height: AppSpacing.lg),
                DayList(day: state.selectedDay),
                SizedBox(height: 80 + MediaQuery.paddingOf(context).bottom),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            unawaited(_openTransactionForm(context, state.selectedDay)),
        child: const Icon(AppIcons.add),
      ),
    );
  }

  Future<void> _openTransactionForm(BuildContext context, LocalDate day) {
    return context.pushNamed(
      AppRoutes.transactionNewName,
      queryParameters: <String, String>{'date': '${day.value}'},
    );
  }

  /// Opens the month/year picker and jumps the calendar to the chosen month.
  ///
  /// [currentMonth] is the month the page is already showing — passed in rather
  /// than read back off the notifier, because a `Notifier`'s `state` is not part
  /// of its public contract (`invalid_use_of_protected_member`).
  ///
  /// Only the *month* is applied: the selected day is left to the notifier's
  /// own clamping, because 31 March has no counterpart in February and
  /// `LocalDate.addMonths` already owns that rule. Setting the day here would be
  /// a second, divergent copy of it.
  Future<void> _pickMonth(
    BuildContext context,
    CalendarNotifier notifier,
    LocalDate currentMonth,
  ) async {
    final chosen = await Navigator.of(context).push<LocalDate>(
      MaterialPageRoute<LocalDate>(
        builder: (_) => MonthYearPickerPage(initialMonth: currentMonth),
      ),
    );
    if (chosen == null) return;

    notifier.jumpToMonth(chosen);
  }
}

/// The two-pane body: grid + summary on the left, the day's transactions right.
///
/// Each pane gets **its own scrollable** rather than sharing one. A single
/// `CustomScrollView` across both would make the day list's length determine the
/// grid's scroll extent, so a busy day would push the month header off screen —
/// which is exactly what the wide layout is supposed to avoid.
class _WideBody extends StatelessWidget {
  const _WideBody({required this.monthPane, required this.dayPane});

  final List<Widget> monthPane;
  final Widget dayPane;

  @override
  Widget build(BuildContext context) {
    final horizontal = AppSpacing.pageHorizontal(
      MediaQuery.sizeOf(context).width,
    );

    return Row(
      // `stretch`, not `start`: both panes are `ListView`s, so `start` hands
      // each one an unbounded box and the first frame throws "Vertical viewport
      // was given unbounded height". `stretch` gives them the row's height,
      // which is what makes the two panes scroll independently — the whole
      // point of the wide layout.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.lg,
              0,
              AppSpacing.lg,
            ),
            children: monthPane,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          flex: 6,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              AppSpacing.lg,
              horizontal,
              AppSpacing.lg,
            ),
            children: <Widget>[dayPane],
          ),
        ),
      ],
    );
  }
}
