import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:ledgerly/features/transactions/presentation/pages/calendar_page.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../categories/domain/fake_category_repository.dart';
import '../domain/fake_transaction_repository.dart';

/// The calendar page at each window size class.
///
/// The split is the thing under test: below medium the page is one scrolling
/// column, at medium and above it is **two independently scrolling panes**. The
/// independence matters — if the day list and the grid shared one scrollable, a
/// busy day would scroll the month header off screen, which defeats the point of
/// having a wide layout at all. So the assertions here are about *structure*
/// (`ListView` count, pane widths) rather than pixel positions, which would be
/// brittle against theme changes.
void main() {
  /// A month with a couple of days that have activity, so the summary card and
  /// the day list render real rows instead of the empty placeholder.
  final day = LocalDate(2026, 10, 3);

  List<Transaction> dayTransactions() => <Transaction>[
    fakeTransaction(
      id: 'txn-coffee',
      categoryId: 'cat-food',
      amountMinor: 4500,
      date: day,
      note: 'Morning coffee',
    ),
    fakeTransaction(
      id: 'txn-pay',
      categoryId: 'cat-salary',
      amountMinor: 500000,
      direction: TransactionDirection.income,
      date: day,
    ),
  ];

  final categories = <Category>[
    fakeCategory(id: 'cat-food', name: 'Food'),
    fakeCategory(id: 'cat-salary', name: 'Salary'),
  ];

  /// Hosts [CalendarPage] at [width] with a fixed month of data.
  ///
  /// Every provider that would otherwise reach the get_it locator is overridden
  /// with a fake, so the real page, grid, summary card and rows all run.
  Widget host(
    double width, {
    Locale? locale,
    double textScale = 1,
    List<Transaction>? transactions,
    FakeTransactionRepository? repository,
    List<Override> extraOverrides = const <Override>[],
  }) {
    final fakes = repository ?? FakeTransactionRepository(
      seed: transactions ?? dayTransactions(),
    );

    return ProviderScope(
      overrides: [
        watchDayTransactionsProvider.overrideWithValue(
          WatchDayTransactions(fakes),
        ),
        watchMonthDailyTotalsProvider.overrideWithValue(
          WatchMonthDailyTotals(fakes),
        ),
        watchDayTotalProvider.overrideWithValue(WatchDayTotal(fakes)),
        watchMonthTotalProvider.overrideWithValue(WatchMonthTotal(fakes)),
        // `_TransactionRow` resolves a category name through this family; the
        // override keeps it off the locator while still returning real names.
        categoryByIdProvider.overrideWith(
          (ref, id) async => categories.firstWhere((c) => c.id == id),
        ),
        currencyProvider.overrideWithValue(CurrencyCode.mmk),
        weekStartProvider.overrideWithValue(WeekStart.monday),
        ...extraOverrides,
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale ?? const Locale('en'),
        supportedLocales: AppLocalization.supportedLocales
            .map(Locale.new)
            .toList(growable: false),
        localizationsDelegates: <LocalizationsDelegate<Object?>>[
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Builder(
            builder: (context) => AppStringsScope(
              lookup: AppStringLookup.of(AppLocalizations.of(context)),
              child: const CalendarPage(),
            ),
          ),
        ),
      ),
    );
  }

  group('compact single column', () {
    testWidgets('should_scroll_the_month_grid_and_the_day_list_together', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.smallPhone));
      await tester.pumpAndSettle();

      // One ListView for the body: grid, summary and day list all inside it.
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('should_show_the_summary_card_and_the_day_list', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.smallPhone));
      await tester.pumpAndSettle();

      expect(find.text('Spent today'), findsOneWidget);
      expect(find.text('Morning coffee'), findsOneWidget);
    });
  });

  group('horizontal month swipe', () {
    /// The month label the switcher currently shows, e.g. "October 2026".
    ///
    /// Read off the rendered `Text` rather than the notifier so the test proves
    /// the *UI* moved, which is the thing a user sees. `calendarProvider` starts
    /// at the real "today", so the tests below assert a *change* rather than a
    /// fixed month — otherwise they would break every New Year.
    String switcherLabel(WidgetTester tester) {
      final labels = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(CalendarPage),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => RegExp(r'\d{4}').hasMatch(s))
          .toList();
      return labels.first;
    }

    /// The label widget itself, used as the drag/fling target.
    Finder labelFinder(WidgetTester tester) => find.descendant(
      of: find.byType(CalendarPage),
      matching: find.text(switcherLabel(tester)),
    );

    testWidgets('should_advance_to_the_next_month_on_a_left_flick', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.phone));
      await tester.pumpAndSettle();

      final before = switcherLabel(tester);

      // A left flick: fast enough to clear the velocity threshold on its own.
      await tester.fling(labelFinder(tester), const Offset(-300, 0), 1200);
      await tester.pumpAndSettle();

      expect(
        switcherLabel(tester),
        isNot(before),
        reason: 'a left flick must move the calendar forward a month',
      );
    });

    testWidgets('should_go_back_a_month_on_a_right_flick', (tester) async {
      await tester.pumpWidget(host(TestWidths.phone));
      await tester.pumpAndSettle();

      final before = switcherLabel(tester);

      await tester.fling(labelFinder(tester), const Offset(300, 0), 1200);
      await tester.pumpAndSettle();

      expect(switcherLabel(tester), isNot(before));
    });

    testWidgets('should_ignore_a_tiny_drag_that_is_neither_flick_nor_drag', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.phone));
      await tester.pumpAndSettle();

      final before = switcherLabel(tester);

      // Slow and short: no velocity, no distance — must not change month, or
      // the grid would jump every time a tap wobbles.
      final gesture = await tester.startGesture(
        tester.getCenter(labelFinder(tester)),
      );
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(const Offset(-6, 0));
        await tester.pump(const Duration(milliseconds: 40));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(switcherLabel(tester), before);
    });

    testWidgets('should_swipe_on_a_wide_layout_too', (tester) async {
      await tester.pumpWidget(host(TestWidths.desktop));
      await tester.pumpAndSettle();

      final before = switcherLabel(tester);
      await tester.fling(labelFinder(tester), const Offset(-300, 0), 1200);
      await tester.pumpAndSettle();

      expect(switcherLabel(tester), isNot(before));
    });

    testWidgets('should_open_the_month_picker_when_the_title_is_tapped', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.phone));
      await tester.pumpAndSettle();

      await tester.tap(labelFinder(tester));
      await tester.pumpAndSettle();

      // The picker's own app-bar title.
      expect(find.text('Jump to month'), findsOneWidget);
    });

    testWidgets('should_jump_to_the_picked_month_and_close_the_picker', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.phone));
      await tester.pumpAndSettle();

      // Open the picker, step a year forward, then choose January.
      await tester.tap(labelFinder(tester));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      await tester.tap(find.text('January'));
      await tester.pumpAndSettle();

      // Back on the calendar, and the header year moved on.
      expect(find.text('Jump to month'), findsNothing);
      expect(switcherLabel(tester), startsWith('January'));
    });
  });

  group('two-pane at medium and above', () {
    testWidgets('should_split_into_two_independently_scrolling_panes', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.tablet));
      await tester.pumpAndSettle();

      // Two ListViews, not one: this is the whole point of the wide layout.
      expect(find.byType(ListView), findsNWidgets(2));
    });

    testWidgets('should_keep_the_month_header_visible_on_a_wide_split', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.desktop));
      await tester.pumpAndSettle();

      // The header lives in the left pane, which the day list cannot scroll.
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text('Morning coffee'), findsOneWidget);
    });

    testWidgets('should_give_the_detail_pane_more_room_than_the_master', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.desktop));
      await tester.pumpAndSettle();

      final panes = tester
          .widgetList<ListView>(find.byType(ListView))
          .toList(growable: false);
      expect(panes, hasLength(2));

      // flex 4 / 6 — the list is the wider pane, matching the single-column
      // emphasis where the day list is the primary content.
      final flexible = tester
          .widgetList<Flexible>(
            find.descendant(
              of: find.byType(Row),
              matching: find.byType(Flexible),
            ),
          )
          .toList(growable: false);
      final flexes = flexible.map((f) => f.flex).toList()..sort();
      expect(flexes, <int>[4, 6]);
    });

    testWidgets('should_not_split_at_compact_even_when_tall', (tester) async {
      await tester.pumpWidget(host(TestWidths.largePhone));
      await tester.pumpAndSettle();

      // 430 px is still a phone: one column.
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('localisation', () {
    testWidgets('should_render_the_myanmar_titles', (tester) async {
      await tester.pumpWidget(
        host(TestWidths.smallPhone, locale: const Locale('my')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ပြက္ခဒိန်'), findsWidgets);
    });
  });

  group('empty day', () {
    testWidgets('should_show_the_empty_placeholder_at_both_layouts', (
      tester,
    ) async {
      for (final width in <double>[TestWidths.smallPhone, TestWidths.desktop]) {
        await tester.pumpWidget(
          host(width, transactions: const <Transaction>[]),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Nothing on this day'),
          findsOneWidget,
          reason: 'empty day state missing at width $width',
        );
      }
    });
  });

  group('every mandated width', () {
    testWidgets('should_lay_out_without_overflowing_at_any_width', (
      tester,
    ) async {
      for (final width in TestWidths.all) {
        await tester.pumpWidget(host(width));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'CalendarPage threw at width $width',
        );
      }
    });

    testWidgets('should_lay_out_without_overflowing_at_text_scale_2', (
      tester,
    ) async {
      for (final width in TestWidths.all) {
        await tester.pumpWidget(host(width, textScale: 2));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'CalendarPage threw at width $width, text scale 2.0',
        );
      }
    });
  });

  group('day row swipe-to-delete and overflow menu', () {
    /// Hosts [CalendarPage] with a known fake repository so the swipe's soft
    /// delete and its undo can be asserted against the same in-memory store the
    /// page mutates.
    Widget hostWithFakes(FakeTransactionRepository fakes) => host(
      TestWidths.phone,
      repository: fakes,
      extraOverrides: <Override>[
        deleteTransactionProvider.overrideWithValue(DeleteTransaction(fakes)),
        restoreTransactionProvider.overrideWithValue(
          RestoreTransaction(fakes),
        ),
      ],
    );

    testWidgets('should_soft_delete_a_row_on_a_left_swipe_and_undo_it', (
      tester,
    ) async {
      final fakes = FakeTransactionRepository(seed: dayTransactions());
      await tester.pumpWidget(hostWithFakes(fakes));
      await tester.pumpAndSettle();

      expect(find.text('Morning coffee'), findsOneWidget);

      // Swipe left (end → start) deletes.
      await tester.fling(
        find.text('Morning coffee'),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // The row leaves the tree immediately (locally dismissed), and the
      // repository recorded a soft delete.
      expect(find.text('Morning coffee'), findsNothing);
      expect(
        fakes.items.firstWhere((t) => t.id == 'txn-coffee').isActive,
        isFalse,
      );

      // The undo snack bar brings it back.
      await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Morning coffee'), findsOneWidget);
      expect(fakes.restoredIds, contains('txn-coffee'));
      expect(
        fakes.items.firstWhere((t) => t.id == 'txn-coffee').isActive,
        isTrue,
      );
    });

    testWidgets('should_not_remove_the_row_when_a_right_swipe_requests_edit', (
      tester,
    ) async {
      final fakes = FakeTransactionRepository(seed: dayTransactions());
      await tester.pumpWidget(hostWithFakes(fakes));
      await tester.pumpAndSettle();

      final before = fakes.items.where((t) => t.isActive).length;

      // Swipe right (start → end) edits: the row must snap back and stay.
      await tester.fling(
        find.text('Morning coffee'),
        const Offset(400, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Morning coffee'), findsOneWidget);
      expect(fakes.items.where((t) => t.isActive).length, before);
    });

    testWidgets('should_offer_edit_and_delete_in_the_overflow_menu', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.phone));
      await tester.pumpAndSettle();

      final menu = find.descendant(
        of: find.ancestor(
          of: find.text('Morning coffee'),
          matching: find.byType(ListTile),
        ),
        matching: find.byIcon(Icons.more_horiz),
      );
      await tester.tap(menu);
      await tester.pumpAndSettle();

      // The menu mirrors the swipe gestures for keyboard / screen-reader users.
      expect(find.text('Edit transaction'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
