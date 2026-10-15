import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/platform/window_size.dart';
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
import 'package:ledgerly/features/transactions/presentation/providers/calendar_notifier.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
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

  /// Hosts [CalendarPage] at a real surface [width] wide with a fixed month of
  /// data.
  ///
  /// Every provider that would otherwise reach the get_it locator is overridden
  /// with a fake, so the real page, grid, summary card and rows all run.
  ///
  /// The width is a genuine surface (via [pumpAppHost]) rather than `MediaQuery`
  /// data alone, because the two-pane assertions measure the panes: a pane that
  /// flexes into its parent reports the test window's width unless the view
  /// itself was resized.
  Future<void> host(
    WidgetTester tester,
    double width, {
    Locale? locale,
    double textScale = 1,
    List<Transaction>? transactions,
    FakeTransactionRepository? repository,
    List<Override> extraOverrides = const <Override>[],
    GoRouter? router,
  }) {
    final fakes =
        repository ??
        FakeTransactionRepository(seed: transactions ?? dayTransactions());

    return pumpAppHost(
      tester,
      router: router,
      size: Size(width, 900),
      locale: locale ?? const Locale('en'),
      textScaler: TextScaler.linear(textScale),
      overrides: <Override>[
        watchDayTransactionsProvider.overrideWithValue(
          WatchDayTransactions(fakes),
        ),
        watchPeriodDailyTotalsProvider.overrideWithValue(
          WatchPeriodDailyTotals(fakes),
        ),
        watchDayTotalProvider.overrideWithValue(WatchDayTotal(fakes)),
        watchPeriodTotalProvider.overrideWithValue(WatchPeriodTotal(fakes)),
        // `_TransactionRow` resolves a category name through this family; the
        // override keeps it off the locator while still returning real names.
        categoryByIdProvider.overrideWith(
          (ref, id) async => categories.firstWhere((c) => c.id == id),
        ),
        currencyProvider.overrideWithValue(CurrencyCode.mmk),
        weekStartProvider.overrideWithValue(WeekStart.monday),
        // Pin the calendar to [day] instead of the real "today".
        //
        // `CalendarNotifier.build()` starts on `DateTime.now()`, but the seed
        // data below is dated [day]. Without this the day list would query the
        // real today, find nothing, and every "the row is there" assertion would
        // depend on the wall clock — passing only when the suite happened to run
        // on 3 Oct. Overriding the notifier makes the tests deterministic and
        // is what lets the day list and the swipe tests see their rows at all.
        calendarProvider.overrideWith(() => _SeededCalendarNotifier(day)),
        ...extraOverrides,
      ],
      // `pumpAppHost` takes exactly one of `home` or `router`; the router owns
      // its own tree, so the page is supplied by the router's route instead.
      home: router == null ? const CalendarPage() : null,
    );
  }

  /// Scrolls the compact body until [target] is on screen, or gives up quietly.
  ///
  /// The calendar is one lazy `ListView`: on a phone the month grid pushes the
  /// day rows below the fold, so they are never built until scrolled to.
  /// `scrollUntilVisible` is unsuitable here because it throws
  /// `Bad state: No element` when its target never materialises, which hides
  /// whether the row was missing or merely far down. A bounded drag loop lets
  /// the assertion that follows produce the meaningful failure instead.
  ///
  /// `pumpAndSettle` after each drag, not a bare `pump`: a drag that leaves
  /// velocity behind starts a ballistic scroll, so a bare pump would measure
  /// mid-flight and the loop could exhaust its budget before the list actually
  /// reached the row.
  ///
  /// Every scrollable is dragged in turn rather than only the first, because the
  /// target may live in either pane: in the compact layout the grid and the day
  /// rows share one `ListView`, but at medium and up the day rows are in the
  /// *second* pane's list.
  Future<void> revealOnCompact(WidgetTester tester, String target) async {
    for (var step = 0; step < 12; step++) {
      if (find.text(target).evaluate().isNotEmpty) return;
      final scrollables = find.byType(ListView);
      final count = scrollables.evaluate().length;
      if (count == 0) return;
      for (var index = 0; index < count; index++) {
        if (find.text(target).evaluate().isNotEmpty) return;
        await tester.drag(scrollables.at(index), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
    }
  }

  group('compact single column', () {
    testWidgets('should_scroll_the_month_grid_and_the_day_list_together', (
      tester,
    ) async {
      await host(tester, TestWidths.smallPhone);
      await tester.pumpAndSettle();

      // One ListView for the body: grid, summary and day list all inside it.
      expect(find.byType(ListView), findsOneWidget);
      // The grid sits above the day list in the same scrollable, so the day's
      // rows start below the fold on a phone and only exist once scrolled to —
      // a lazy list never builds what is off-screen.
      await revealOnCompact(tester, 'Food');
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('should_show_the_summary_card_and_the_day_list', (
      tester,
    ) async {
      await host(tester, TestWidths.smallPhone);
      await tester.pumpAndSettle();

      expect(find.text('Spent today'), findsOneWidget);
      await revealOnCompact(tester, 'Morning coffee');
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
      await host(tester, TestWidths.phone);
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
      await host(tester, TestWidths.phone);
      await tester.pumpAndSettle();

      final before = switcherLabel(tester);

      await tester.fling(labelFinder(tester), const Offset(300, 0), 1200);
      await tester.pumpAndSettle();

      expect(switcherLabel(tester), isNot(before));
    });

    testWidgets('should_ignore_a_tiny_drag_that_is_neither_flick_nor_drag', (
      tester,
    ) async {
      await host(tester, TestWidths.phone);
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
      await host(tester, TestWidths.desktop);
      await tester.pumpAndSettle();

      final before = switcherLabel(tester);
      await tester.fling(labelFinder(tester), const Offset(-300, 0), 1200);
      await tester.pumpAndSettle();

      expect(switcherLabel(tester), isNot(before));
    });

    testWidgets('should_open_the_month_picker_when_the_title_is_tapped', (
      tester,
    ) async {
      await host(tester, TestWidths.phone);
      await tester.pumpAndSettle();

      await tester.tap(labelFinder(tester));
      await tester.pumpAndSettle();

      // The picker's own app-bar title.
      expect(find.text('Jump to month'), findsOneWidget);
    });

    testWidgets('should_jump_to_the_picked_month_and_close_the_picker', (
      tester,
    ) async {
      await host(tester, TestWidths.phone);
      await tester.pumpAndSettle();

      // Open the picker, step a year forward, then choose January.
      await tester.tap(labelFinder(tester));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(AppIcons.chevronRight));
      await tester.pumpAndSettle();
      // The tiles are labelled by CLDR's month+year (`formatMonthYear`), so match
      // on the month prefix rather than the bare name — the year depends on the
      // real "today" and would otherwise make this break every New Year.
      await tester.tap(find.textContaining('January '));
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
      await host(tester, TestWidths.tablet);
      await tester.pumpAndSettle();

      // Two ListViews, not one: this is the whole point of the wide layout.
      expect(find.byType(ListView), findsNWidgets(2));
    });

    testWidgets('should_keep_the_month_header_visible_on_a_wide_split', (
      tester,
    ) async {
      await host(tester, TestWidths.desktop);
      await tester.pumpAndSettle();

      // The header lives in the left pane, which the day list cannot scroll.
      expect(find.byIcon(AppIcons.chevronLeft), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
      // The day rows are inside the right pane's own scrollable, so they are
      // below the fold on a 900 px tall split until that pane is scrolled.
      await revealOnCompact(tester, 'Morning coffee');
      expect(find.text('Morning coffee'), findsOneWidget);
    });

    testWidgets('should_give_the_detail_pane_more_room_than_the_master', (
      tester,
    ) async {
      await host(tester, TestWidths.desktop);
      await tester.pumpAndSettle();

      final panes = tester
          .widgetList<ListView>(find.byType(ListView))
          .toList(growable: false);
      expect(panes, hasLength(2));

      // flex 4 / 6 — the day list is the wider pane, matching the
      // single-column emphasis where it is the primary content.
      //
      // `Expanded`, not `Flexible`: the panes are built as `Expanded(flex: …)`,
      // and `find.byType` matches an exact runtime type, so `find.byType(
      // Flexible)` never sees an `Expanded` (they are parent and child in the
      // class hierarchy, not the same runtime type) and the list came back
      // empty. Scoped to the `Expanded`s that wrap the two pane `ListView`s
      // rather than `find.byType(Row)` at large, so an unrelated flex deeper in
      // the tree cannot be collected.
      final flexes =
          tester
              .widgetList<Expanded>(
                find.ancestor(
                  of: find.byType(ListView),
                  matching: find.byType(Expanded),
                ),
              )
              .map((f) => f.flex)
              .toList()
            ..sort();
      expect(flexes, <int>[4, 6]);
    });

    testWidgets('should_not_split_at_compact_even_when_tall', (tester) async {
      await host(tester, TestWidths.largePhone);
      await tester.pumpAndSettle();

      // 430 px is still a phone: one column.
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('localisation', () {
    testWidgets('should_render_the_myanmar_titles', (tester) async {
      await host(tester, TestWidths.smallPhone, locale: const Locale('my'));
      await tester.pumpAndSettle();

      expect(find.text('ပြက္ခဒိန်'), findsWidgets);
    });
  });

  group('empty day', () {
    testWidgets('should_show_the_empty_placeholder_at_both_layouts', (
      tester,
    ) async {
      for (final width in <double>[TestWidths.smallPhone, TestWidths.desktop]) {
        await host(tester, width, transactions: const <Transaction>[]);
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
    /// Pumps [CalendarPage] at every mandated width and asserts nothing threw.
    ///
    /// Each width is pumped into a **fresh** tree: the app is unmounted with a
    /// `SizedBox` between iterations. Re-pumping on top of the previous tree
    /// instead trips a framework assertion in
    /// `_RenderObjectSemantics._collectChildMergeUpAndSiblingGroup`
    /// ("!childSemantics.renderObject._needsLayout is not true") — a lazy
    /// scrollable carrying `MergeSemantics` rows (the day list) has its
    /// semantics updated while a render object is still dirty. Unmounting is
    /// what a separate `testWidgets` per width would do for free.
    ///
    /// `pumpAndSettle` cannot be used here: the page shows a
    /// `CircularProgressIndicator` while a provider resolves, and an
    /// indeterminate spinner never settles.
    Future<void> laysOutAtEveryWidth(
      WidgetTester tester, {
      required double textScale,
    }) async {
      for (final width in TestWidths.all) {
        await host(tester, width, textScale: textScale);
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'CalendarPage threw at width $width, text scale $textScale',
        );

        // Unmount so the next width starts from a clean tree.
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }

    testWidgets('should_lay_out_without_overflowing_at_any_width', (
      tester,
    ) async {
      await laysOutAtEveryWidth(tester, textScale: 1);
    });

    testWidgets('should_lay_out_without_overflowing_at_text_scale_2', (
      tester,
    ) async {
      await laysOutAtEveryWidth(tester, textScale: 2);
    });
  });

  group('day row swipe-to-delete and overflow menu', () {
    /// Hosts [CalendarPage] with a known fake repository so the swipe's soft
    /// delete and its undo can be asserted against the same in-memory store the
    /// page mutates.
    Future<void> hostWithFakes(
      WidgetTester tester,
      FakeTransactionRepository fakes, {
      GoRouter? router,
    }) => host(
      tester,
      TestWidths.phone,
      repository: fakes,
      router: router,
      extraOverrides: <Override>[
        deleteTransactionProvider.overrideWithValue(DeleteTransaction(fakes)),
        restoreTransactionProvider.overrideWithValue(RestoreTransaction(fakes)),
      ],
    );

    /// Scrolls the day's rows into view.
    ///
    /// The calendar body is one lazy `ListView` with the month grid above the
    /// day list, so on a phone the rows start below the fold and are not built
    /// until they are scrolled to. Every test in this group acts on a row, so
    /// they all begin here rather than assuming the row is already on screen.
    Future<void> revealRows(WidgetTester tester) async {
      await revealOnCompact(tester, 'Morning coffee');
      await tester.pumpAndSettle();
    }

    testWidgets('should_soft_delete_a_row_on_a_left_swipe_and_undo_it', (
      tester,
    ) async {
      final fakes = FakeTransactionRepository(seed: dayTransactions());
      await hostWithFakes(tester, fakes);
      await tester.pumpAndSettle();
      await revealRows(tester);

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
      // A right swipe *navigates* to the edit form (`context.pushNamed`), so the
      // page needs a router above it — without one the swipe throws "No GoRouter
      // found in context" before the assertion runs, and the test would be
      // measuring the missing router rather than the swipe. The destination is
      // a stub: the point is that the swipe routes to *edit* and leaves the row
      // in place, not what the form looks like.
      final router = GoRouter(
        initialLocation: AppRoutes.calendar,
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.calendar,
            name: AppRoutes.calendarName,
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: AppRoutes.transactionNew,
            name: AppRoutes.transactionNewName,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Edit transaction form')),
            ),
            // A right swipe edits *an existing* row, so the destination is the
            // nested edit route (`:id/edit`), not the create one. Both are
            // stubbed to the same marker: the assertion is that the swipe routed
            // to the form at all.
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.transactionEditRelative,
                name: AppRoutes.transactionEditName,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Edit transaction form')),
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await hostWithFakes(tester, fakes, router: router);
      await tester.pumpAndSettle();
      await revealRows(tester);

      final before = fakes.items.where((t) => t.isActive).length;

      // Swipe right (start → end) edits: the row must snap back and stay.
      await tester.fling(
        find.text('Morning coffee'),
        const Offset(400, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // The edit route opened — that is the swipe's actual effect.
      expect(find.text('Edit transaction form'), findsOneWidget);
      expect(fakes.items.where((t) => t.isActive).length, before);
    });

    testWidgets('should_offer_edit_and_delete_in_the_overflow_menu', (
      tester,
    ) async {
      await host(tester, TestWidths.phone);
      await tester.pumpAndSettle();
      await revealRows(tester);

      final menu = find.descendant(
        of: find.ancestor(
          of: find.text('Morning coffee'),
          matching: find.byType(ListTile),
        ),
        matching: find.byIcon(AppIcons.moreHorizontal),
      );
      await tester.tap(menu);
      await tester.pumpAndSettle();

      // The menu mirrors the swipe gestures for keyboard / screen-reader users.
      expect(find.text('Edit transaction'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('pay-cycle month start day', () {
    testWidgets('shows month name when monthStartDay is 1', (tester) async {
      await host(
        tester,
        TestWidths.phone,
        extraOverrides: <Override>[monthStartDayProvider.overrideWithValue(1)],
      );
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Pay cycle'), findsNothing);
    });

    testWidgets(
      'shows date range and Pay cycle caption when monthStartDay is 10',
      (tester) async {
        await host(
          tester,
          TestWidths.phone,
          extraOverrides: <Override>[
            monthStartDayProvider.overrideWithValue(10),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.text('Pay cycle'), findsOneWidget);
        expect(find.textContaining(' – '), findsOneWidget);
      },
    );

    testWidgets(
      'shows tiny month label on the 1st of calendar month in pay-cycle mode',
      (tester) async {
        await host(
          tester,
          TestWidths.phone,
          extraOverrides: <Override>[
            monthStartDayProvider.overrideWithValue(10),
          ],
        );
        await tester.pumpAndSettle();

        // In period Sep 10 – Oct 9 containing day (Oct 3), Oct 1 appears with label 'Oct'.
        expect(find.text('Oct'), findsOneWidget);
      },
    );
  });

  group('Day Capsule spec (docs/Design.md §6.2)', () {
    /// The capsule is the 4 px bar under a day number. It is found by its
    /// `Container` decoration rather than a type, since `_Capsule` is private.
    ///
    /// The width is asserted as a *proportion of the rendered grid row* (60 %),
    /// not an absolute pixel count: the row sits inside page padding, so an
    /// absolute number would pin the padding rather than the spec invariant
    /// and break every time the insets change.
    Finder capsuleOf(double expectedWidth) => find.byWidgetPredicate((w) {
      if (w is! Container) return false;
      final d = w.decoration;
      if (d is! BoxDecoration) return false;
      final c = w.constraints;
      if (c == null) return false;
      return (c.maxHeight - 4).abs() < 0.01 &&
          (c.maxWidth - expectedWidth).abs() < 0.5;
    });

    /// Width of one 7-column grid row currently on screen.
    double gridRowWidth(WidgetTester tester) {
      final rows = find.byWidgetPredicate(
        (w) =>
            w is Row &&
            w.children.length == 7 &&
            w.children.every((c) => c is Expanded),
      );
      expect(rows, findsWidgets);
      return tester.getSize(rows.first).width;
    }

    testWidgets('should_size_the_capsule_to_60_percent_of_its_cell', (
      tester,
    ) async {
      await host(tester, TestWidths.phone);
      await tester.pumpAndSettle();

      final expected = gridRowWidth(tester) / 7 * 0.6;
      expect(
        capsuleOf(expected),
        findsWidgets,
        reason: 'capsule width must be 60% of the cell, not a fixed 24 px',
      );
    });

    testWidgets('should_widen_the_capsule_when_the_grid_stretches', (
      tester,
    ) async {
      // A tablet cell is far wider than a phone's, so a fixed-width capsule
      // would keep its absolute size instead of its proportion.
      await host(tester, TestWidths.tablet);
      await tester.pumpAndSettle();

      final expected = gridRowWidth(tester) / 7 * 0.6;
      expect(capsuleOf(expected), findsWidgets);
    });

    testWidgets(
      'should_wrap_the_selected_cell_in_a_radius_md_fill_not_a_circle',
      (tester) async {
        await host(tester, TestWidths.phone);
        await tester.pumpAndSettle();

        // The selected day is Oct 3. Find the DecoratedBox carrying the
        // selection fill and assert its corner shape. The light-theme
        // `brandSubtle` is `AppPalette.jade100`; the host renders light.
        final selectionFill = find.byWidgetPredicate((w) {
          if (w is! DecoratedBox) return false;
          final d = w.decoration;
          return d is BoxDecoration &&
              d.color == AppPalette.jade100 &&
              d.borderRadius == AppRadius.borderMd;
        });

        expect(
          selectionFill,
          findsWidgets,
          reason: '§6.2 selected cell is brandSubtle at radius.md',
        );
      },
    );
  });
}

/// A [CalendarNotifier] that starts on a fixed day rather than the real
/// "today".
///
/// Test-only. The page's own notifier pins itself to `DateTime.now()`, which
/// makes any assertion about the day list depend on the wall clock; seeding the
/// visible month and selected day here removes that dependency entirely.
class _SeededCalendarNotifier extends CalendarNotifier {
  _SeededCalendarNotifier(this._day);

  final LocalDate _day;

  @override
  CalendarState build() {
    final calculator = ref.watch(periodCalculatorProvider);
    return CalendarState(
      visiblePeriod: calculator.containing(_day),
      selectedDay: _day,
      isTodaySelected: false,
    );
  }
}
