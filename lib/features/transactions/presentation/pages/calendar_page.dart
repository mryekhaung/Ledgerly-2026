import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/utils/month_grid_layout.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/core/widgets/month_year_picker_page.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:ledgerly/features/transactions/presentation/providers/calendar_notifier.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:ledgerly/l10n/app_localization.dart';
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
    final monthPane = <Widget>[
      _MonthSwipeArea(
        onPrevious: () => notifier.shiftMonth(-1),
        onNext: () => notifier.shiftMonth(1),
        child: Column(
          children: <Widget>[
            _MonthSwitcher(
              month: state.visibleMonth,
              onPrevious: () => notifier.shiftMonth(-1),
              onNext: () => notifier.shiftMonth(1),
              onPickMonth: () => _pickMonth(context, notifier),
            ),
            const SizedBox(height: AppSpacing.md),
            _WeekdayHeader(weekStart: weekStart),
            const SizedBox(height: AppSpacing.sm),
            _CalendarGrid(
              month: state.visibleMonth,
              selectedDay: state.selectedDay,
              weekStart: weekStart,
              onSelectDay: notifier.selectDay,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      _SummaryCard(day: state.selectedDay),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings('navigationCalendar')),
        actions: <Widget>[
          if (state.canGoToToday)
            TextButton(
              onPressed: notifier.goToToday,
              child: Text(strings('calendarToday')),
            ),
        ],
      ),
      body: sizeClass.isTwoPaneCapable
          ? _WideBody(
              monthPane: monthPane,
              dayPane: _DayList(day: state.selectedDay),
            )
          : ListView(
              padding: ResponsiveInsets.pageHorizontal(context),
              children: <Widget>[
                ...monthPane,
                const SizedBox(height: AppSpacing.lg),
                _DayList(day: state.selectedDay),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTransactionForm(context, state.selectedDay),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openTransactionForm(BuildContext context, LocalDate day) {
    context.pushNamed(
      AppRoutes.transactionNewName,
      queryParameters: <String, String>{'date': '${day.value}'},
    );
  }

  /// Opens the month/year picker and jumps the calendar to the chosen month.
  ///
  /// Only the *month* is applied: the selected day is left to the notifier's
  /// own clamping, because 31 March has no counterpart in February and
  /// `LocalDate.addMonths` already owns that rule. Setting the day here would be
  /// a second, divergent copy of it.
  Future<void> _pickMonth(
    BuildContext context,
    CalendarNotifier notifier,
  ) async {
    final chosen = await Navigator.of(context).push<LocalDate>(
      MaterialPageRoute<LocalDate>(
        builder: (_) =>
            MonthYearPickerPage(initialMonth: notifier.state.visibleMonth),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
        SizedBox(width: AppSpacing.xl),
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

/// Makes the calendar grid horizontally swipeable, one month per gesture.
///
/// Uses `onHorizontalDragEnd` rather than a `PageView`, on purpose: a `PageView`
/// would have to materialise adjacent months and keep them alive, and the data
/// for a month the user never reaches would still be subscribed. The visible
/// month is a single value in [CalendarNotifier]; a swipe is just another way to
/// change it, exactly like the `‹ ›` buttons. That keeps one code path for
/// month navigation and means the arrow buttons and the gesture can never
/// disagree.
///
/// A velocity threshold (the primary signal) plus a distance threshold (for a
/// slow, deliberate drag) is the standard pairing — velocity alone drops slow
/// drags, distance alone fires on an accidental short flick.
class _MonthSwipeArea extends StatefulWidget {
  const _MonthSwipeArea({
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  @override
  State<_MonthSwipeArea> createState() => _MonthSwipeAreaState();
}

class _MonthSwipeAreaState extends State<_MonthSwipeArea> {
  /// Fraction of the widget's width a slow drag must cover to count.
  static const double _distanceFraction = 0.15;

  /// Logical px/s above which a flick counts regardless of distance.
  static const double _velocityThreshold = 250;

  /// Total horizontal distance travelled during the current drag.
  ///
  /// Accumulated from `onHorizontalDragUpdate` rather than read off
  /// `DragEndDetails.localPosition`, because that field is the pointer's final
  /// *position*, not the distance moved — comparing an absolute coordinate
  /// against a width fraction would fire at the wrong place on the screen.
  double _dragged = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // `translucent` so the gesture is picked up over the grid's gaps, where
      // there is no painted child to hit-test against.
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dragged = 0,
      onHorizontalDragUpdate: (details) => _dragged += details.delta.dx,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final threshold = MediaQuery.sizeOf(context).width * _distanceFraction;
        final draggedFarEnough = _dragged.abs() > threshold;

        // Negative = finger moved left = advance to the next month. Matches
        // every calendar the user has ever used.
        if (velocity < -_velocityThreshold ||
            (velocity < 0 && draggedFarEnough)) {
          AppFeedback.selection();
          widget.onNext();
        } else if (velocity > _velocityThreshold ||
            (velocity > 0 && draggedFarEnough)) {
          AppFeedback.selection();
          widget.onPrevious();
        }
      },
      child: widget.child,
    );
  }
}

/// The `< March 2026 >` header.
///
/// The title in the middle is tappable and opens the month/year picker — the
/// only way to cross a year boundary without stepping through twelve `‹ ›`
/// taps. The chevrons stay for the common one-month move.
class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onPickMonth,
  });

  final LocalDate month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final label = MaterialLocalizations.of(context)
        .formatMonthYear(DateTime(month.year, month.month));

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: strings('calendarPreviousMonth'),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.borderSm,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPickMonth,
              // A tooltip doubles as the accessibility hint: a bare tappable
              // month name gives no clue that it opens a picker.
              child: Tooltip(
                message: strings('calendarPickMonth'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // The caret is the affordance; without it the label reads
                      // as a heading, not a control.
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: strings('calendarNextMonth'),
        ),
      ],
    );
  }
}

/// The `M T W T F S S` header, rotated to match the grid's week start.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.weekStart});

  final GridWeekStart weekStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final localizations = MaterialLocalizations.of(context);

    // `narrowWeekdays` is Sunday-indexed (0 = S), so for a Monday-first grid the
    // columns are days 1..6 then Sunday (index 0). A Sunday-first grid is simply
    // days 0..6 in order — which is why this rotates with an offset rather than
    // reordering a literal list that would then have to be kept in two places.
    final firstIndex = weekStart == GridWeekStart.monday ? 1 : 0;

    return Row(
      children: <Widget>[
        for (var column = 0; column < DateTime.daysPerWeek; column++)
          Expanded(
            child: Center(
              child: Text(
                localizations.narrowWeekdays[(firstIndex + column) %
                    DateTime.daysPerWeek],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The month grid with day capsules.
///
/// Watches `monthDailyTotalsProvider` so the capsule intensities update when
/// transactions change, without rebuilding the whole page.
class _CalendarGrid extends ConsumerWidget {
  const _CalendarGrid({
    required this.month,
    required this.selectedDay,
    required this.weekStart,
    required this.onSelectDay,
  });

  final LocalDate month;
  final LocalDate selectedDay;
  final GridWeekStart weekStart;
  final ValueChanged<LocalDate> onSelectDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(monthDailyTotalsProvider);
    final totals = totalsAsync.value ?? const <DailyTotal>[];

    return _MonthGrid(
      month: month,
      selectedDay: selectedDay,
      weekStart: weekStart,
      totals: totals,
      onSelectDay: onSelectDay,
    );
  }
}

/// The grid widget itself, separated so it can be unit-tested with fake data.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.weekStart,
    required this.totals,
    required this.onSelectDay,
  });

  final LocalDate month;
  final LocalDate selectedDay;
  final GridWeekStart weekStart;
  final List<DailyTotal> totals;
  final ValueChanged<LocalDate> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final cells = MonthGridLayout.cells(month, weekStart: weekStart);
    final rowCount = cells.length ~/ MonthGridLayout.daysPerWeek;
    final today = LocalDate.fromDateTime(DateTime.now());
    final intensities = _intensities(totals);

    return Column(
      children: <Widget>[
        for (var row = 0; row < rowCount; row++)
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
                    final day => _DayCell(
                      day: day,
                      isSelected: day.value == selectedDay.value,
                      isToday: day.value == today.value,
                      intensity: intensities[day.value],
                      onTap: () => onSelectDay(day),
                    ),
                  },
                ),
            ],
          ),
      ],
    );
  }

  /// Maps each day's packed value to its capsule intensity.
  ///
  /// Intensity is the absolute net divided by the 95th-percentile absolute net
  /// of the month, clamped to [0, 1] and quantized to 5 steps
  /// (`docs/Design.md` §6.2).
  static Map<int, _Intensity> _intensities(List<DailyTotal> totals) {
    if (totals.isEmpty) return const <int, _Intensity>{};

    final nets =
        totals
            .where((t) => t.hasActivity)
            .map((t) => t.netMinor.abs())
            .toList(growable: false)
          ..sort();

    if (nets.isEmpty) return const <int, _Intensity>{};

    final p95Index = ((nets.length - 1) * 0.95).round();
    final p95 = nets[p95Index];
    if (p95 == 0) return const <int, _Intensity>{};

    return <int, _Intensity>{
      for (final total in totals)
        if (total.hasActivity)
          total.date.value: _Intensity._fromNet(
            total.netMinor,
            p95,
            total.dominantDirection,
          ),
    };
  }
}

/// A day's capsule intensity and direction.
///
/// Five quantized steps (0–4) so the grid reads as texture, not noise.
final class _Intensity {
  const _Intensity._(this.step, this.direction);

  /// 0 = no capsule, 1–4 = increasing fill.
  final int step;

  /// Which colour family to use.
  final TransactionDirection? direction;

  factory _Intensity._fromNet(
    int netMinor,
    int p95,
    TransactionDirection? dominant,
  ) {
    final raw = netMinor.abs() / p95;
    final clamped = raw > 1.0 ? 1.0 : raw;
    // Quantize to 5 steps: 0, 0.25, 0.5, 0.75, 1.0 → steps 0–4.
    final step = (clamped * 4).round();
    return _Intensity._(step, dominant);
  }
}

/// One tappable day cell in the grid.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.intensity,
    required this.onTap,
  });

  final LocalDate day;
  final bool isSelected;
  final bool isToday;
  final _Intensity? intensity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colors.brandSubtle : null,
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: colors.brandPrimary, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // The number sits in a fixed-height slot and the capsule
                  // hangs below it, rather than the pair being centred as a
                  // group. If the pair were centred, adding a capsule would
                  // nudge the number *up*, so the digits would visibly shift
                  // row to row on a month where some days have activity and
                  // others do not — the grid would look misaligned even though
                  // every cell is centred. Fixing the number's slot keeps every
                  // digit on one baseline and lets the capsule use the leftover
                  // space instead.
                  SizedBox(
                    height: 20,
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? colors.brandPrimary
                              : colors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ),
                  if (intensity case final i?) _Capsule(intensity: i),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 4 px rounded bar under a day number.
class _Capsule extends StatelessWidget {
  const _Capsule({required this.intensity});

  final _Intensity intensity;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    // `transfer` shares the expense/neutral treatment rather than getting its own
    // colour: v0.1 cannot create one (`docs/Roadmap.md`), and inventing a colour
    // for an unreachable state would be untested design. The case is spelled out
    // anyway so the switch stays exhaustive when `transfer` ships in v0.3.
    final baseColor = switch (intensity.direction) {
      TransactionDirection.income => colors.moneyInSubtle,
      TransactionDirection.expense ||
      TransactionDirection.transfer ||
      null => colors.moneyOutSubtle,
    };
    // Alpha maps step 1→64, 2→128, 3→192, 4→255 (0x40, 0x80, 0xC0, 0xFF).
    final alpha = intensity.step * 64;

    return Container(
      width: 24,
      height: 4,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: baseColor.withAlpha(alpha.clamp(0, 255)),
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
    );
  }
}

/// The summary card for the selected day.
///
/// Shows "Spent today" with the net, plus income and expense breakdown.
class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.day});

  final LocalDate day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final currency = ref.watch(currencyProvider);
    final totalAsync = ref.watch(selectedDayTotalProvider);
    final total = totalAsync.value ?? DailyTotal.empty(day, currency);

    // The card is scoped to the *selected day*: `selectedDayTotalProvider` is a
    // day-level SQL aggregate, so switching days repaints this without touching
    // the month figures the grid uses.
    final netMoney = Money.minor(total.netMinor, currency);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings('calendarSpentToday'),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AmountText(netMoney, style: AmountStyle.large, signed: true),
          const SizedBox(height: AppSpacing.md),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryColumn(
                  label: strings('calendarIncome'),
                  amount: Money.minor(total.incomeMinor, currency),
                  color: colors.moneyIn,
                ),
              ),
              Expanded(
                child: _SummaryColumn(
                  label: strings('calendarExpense'),
                  amount: Money.minor(total.expenseMinor, currency),
                  color: colors.moneyOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One side of the summary card footer.
class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final Money amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppThemeColors.of(context).textSecondary),
      ),
      const SizedBox(height: AppSpacing.xs),
      AmountText(amount, style: AmountStyle.row, signed: false, color: color),
    ],
  );
}

/// The list of transactions for the selected day.
class _DayList extends ConsumerStatefulWidget {
  const _DayList({required this.day});

  final LocalDate day;

  @override
  ConsumerState<_DayList> createState() => _DayListState();
}

/// State for [_DayList].
///
/// Holds the set of ids dismissed by a swipe so the row is removed from the
/// visible list on the same frame the gesture completes. The soft delete only
/// propagates through the provider stream a frame later, and a `Dismissible`
/// whose key is still in the parent's children after `onDismissed` throws — so
/// we drop it locally first and let the stream confirm the removal.
class _DayListState extends ConsumerState<_DayList> {
  final Set<String> _dismissed = <String>{};

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final transactionsAsync = ref.watch(selectedDayTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        final visible = transactions
            .where((t) => !_dismissed.contains(t.id))
            .toList(growable: false);

        return visible.isEmpty
            ? StatePlaceholder(
                icon: Icons.inbox_outlined,
                title: strings('calendarEmptyDay'),
                body: strings('stateEmptyBody'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _DayHeader(day: widget.day),
                  const SizedBox(height: AppSpacing.sm),
                  for (final transaction in visible)
                    _TransactionRow(
                      transaction: transaction,
                      onRemoved: (id) => setState(() => _dismissed.add(id)),
                      onRestored: (id) => setState(() => _dismissed.remove(id)),
                    ),
                ],
              );
      },
      loading: () => const LoadingPlaceholder(),
      error: (_, __) => ErrorBanner(
        message: strings('stateErrorBody'),
        onRetry: () => ref.invalidate(selectedDayTransactionsProvider),
      ),
    );
  }
}

/// The sticky date header above the day list.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final LocalDate day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final localizations = MaterialLocalizations.of(context);
    final label = localizations.formatMediumDate(day.toUtcDateTime().toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

/// One transaction in the day list.
///
/// Direct manipulation: swipe **left** to delete (a 5-second undo snack bar
/// follows, because the delete is *soft* — the same tombstone a v0.4 sync will
/// propagate, so the undo is honest rather than decorative) and swipe **right**
/// to edit, on top of the existing tap-to-edit. A trailing overflow menu
/// mirrors both actions for keyboard and screen-reader users, who cannot
/// perform a swipe (`docs/Roadmap.md` Phase 1).
class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({
    required this.transaction,
    required this.onRemoved,
    required this.onRestored,
  });

  final Transaction transaction;

  /// Adds [transaction.id] to the parent's locally-dismissed set when a delete
  /// swipe completes, so the row leaves the tree before the provider stream
  /// confirms the soft delete.
  final ValueChanged<String> onRemoved;

  /// Removes [transaction.id] from that set when an undo restores it, letting
  /// the row reappear from the provider data.
  final ValueChanged<String> onRestored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final category = ref
        .watch(categoryByIdProvider(transaction.categoryId))
        .value;

    return Dismissible(
      key: ValueKey<String>(transaction.id),
      direction: DismissDirection.horizontal,
      // Swiping right (start → end) edits: navigate, then snap back so the row
      // never disappears for an action that keeps it.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editTransaction(context, transaction);
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onRemoved(transaction.id);
          _deleteTransaction(context, ref, transaction);
        }
      },
      background: _SwipeAffordance(
        alignStart: true,
        icon: Icons.edit_outlined,
        label: strings('transactionEdit'),
        color: colors.brandSubtle,
        iconColor: colors.brandPrimary,
      ),
      secondaryBackground: _SwipeAffordance(
        alignStart: false,
        icon: Icons.delete_outline,
        label: strings('actionDelete'),
        color: colors.moneyOutSubtle,
        iconColor: colors.moneyOut,
      ),
      child: ListTile(
        onTap: () => _editTransaction(context, transaction),
        leading: category == null
            ? const SizedBox.square(dimension: 40)
            : CategoryGem(
                colorValue: category.colorValue,
                iconKey: category.iconKey,
                size: CategoryGemSize.md,
              ),
        title: Text(
          category?.name ?? transaction.categoryId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: transaction.note == null
            ? null
            : Text(
                transaction.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AmountText(
              transaction.amount,
              style: AmountStyle.row,
              signed: true,
              color: transaction.direction == TransactionDirection.income
                  ? colors.moneyIn
                  : colors.moneyOut,
            ),
            const SizedBox(width: AppSpacing.xs),
            PopupMenuButton<_TransactionAction>(
              icon: Icon(Icons.more_horiz, color: colors.textSecondary),
              onSelected: (action) => switch (action) {
                _TransactionAction.edit => _editTransaction(
                  context,
                  transaction,
                ),
                _TransactionAction.delete => _deleteTransaction(
                  context,
                  ref,
                  transaction,
                ),
              },
              itemBuilder: (context) => <PopupMenuEntry<_TransactionAction>>[
                PopupMenuItem<_TransactionAction>(
                  value: _TransactionAction.edit,
                  child: Text(strings('transactionEdit')),
                ),
                PopupMenuItem<_TransactionAction>(
                  value: _TransactionAction.delete,
                  child: Text(strings('actionDelete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editTransaction(BuildContext context, Transaction transaction) {
    context.pushNamed(
      AppRoutes.transactionEditName,
      pathParameters: <String, String>{'id': transaction.id},
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final strings = AppStrings.of(context);
    // A destructive action buzzes before the snack bar is read, so deleting
    // feels different from tapping a row.
    AppFeedback.destructive();
    final result = await ref.read(deleteTransactionProvider).call((
      id: transaction.id,
    ));
    if (!context.mounted) return;

    if (result.isErr) {
      AppFeedback.failure(context, message: strings('stateErrorBody'));
      // A failed delete must not leave the row hidden.
      onRestored(transaction.id);
      return;
    }

    AppFeedback.undoable(
      context,
      message: strings('transactionDeleted'),
      undoLabel: undoLabelFor(context),
      onUndo: () => _restoreTransaction(context, ref, transaction),
    );
  }

  Future<void> _restoreTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final result = await ref.read(restoreTransactionProvider).call((
      id: transaction.id,
    ));
    if (!context.mounted) return;

    if (result.isSuccess) {
      onRestored(transaction.id);
      AppFeedback.success();
    } else {
      AppFeedback.failure(
        context,
        message: AppStrings.of(context)('stateErrorBody'),
      );
    }
  }
}

/// The colored panel revealed behind a transaction row as it is swiped.
///
/// One instance per swipe direction: the edit affordance on the start side, the
/// delete affordance on the end side. Kept tiny and declarative so both
/// backgrounds share one painter.
class _SwipeAffordance extends StatelessWidget {
  const _SwipeAffordance({
    required this.alignStart,
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  final bool alignStart;
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    alignment: alignStart
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd,
    color: color,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: <Widget>[
        Icon(icon, color: iconColor),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: iconColor),
        ),
      ],
    ),
  );
}

/// What the row's overflow menu can do — the swipe-free alternative.
enum _TransactionAction { edit, delete }
