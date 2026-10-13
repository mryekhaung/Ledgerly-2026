import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/pages/month_starts_on_page.dart';
import 'package:ledgerly/features/settings/presentation/pages/settings_page.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:ledgerly/features/transactions/presentation/pages/calendar_page.dart';
import 'package:ledgerly/features/transactions/presentation/providers/calendar_notifier.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/app_test_host.dart';

void main() {
  group('Accessibility & Semantics Pass', () {
    testWidgets('CalendarPage interactive controls expose accessible semantics', (
      tester,
    ) async {
      final today = LocalDate.fromDateTime(DateTime.now());
      final period = BudgetPeriod(
        start: today.firstDayOfMonth,
        end: LocalDate(today.year, today.month, LocalDate.daysInMonth(today.year, today.month)),
      );

      await pumpAppHost(
        tester,
        overrides: <Override>[
          settingsProvider.overrideWith((_) => Stream.value(AppSettings.defaults)),
          currencyProvider.overrideWithValue(CurrencyCode.usd),
          monthStartDayProvider.overrideWithValue(1),
          calendarProvider.overrideWith(
            () => _FakeCalendarNotifier(
              CalendarState(
                visiblePeriod: period,
                visibleMonth: period.start,
                selectedDay: today,
                isTodaySelected: true,
              ),
            ),
          ),
          selectedDayTransactionsProvider.overrideWith(
            (_) => Stream.value(const <Transaction>[]),
          ),
          monthDailyTotalsProvider.overrideWith(
            (_) => Stream.value(const <DailyTotal>[]),
          ),
          selectedDayTotalProvider.overrideWith(
            (_) => Stream.value(DailyTotal.empty(today, CurrencyCode.usd)),
          ),
        ],
        size: const Size(360, 800),
        home: const CalendarPage(),
      );
      await tester.pumpAndSettle();

      // 1. Previous and Next Month buttons expose tooltips/semantics
      expect(find.byTooltip('Previous month'), findsOneWidget);
      expect(find.byTooltip('Next month'), findsOneWidget);

      // 2. Month switcher title has accessible month picker tooltip
      expect(find.byTooltip('Jump to month'), findsOneWidget);

      // 3. Day cells have button semantics and selected state
      final selectedDayFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.selected == true,
      );
      final selectedDaySemantics = tester.getSemantics(selectedDayFinder);
      expect(selectedDaySemantics.flagsCollection.isSelected.toString(), 'Tristate.isTrue');
      expect(selectedDaySemantics.flagsCollection.isButton, isTrue);
      expect(selectedDaySemantics.label, contains('${today.day}'));

      // 4. FAB has button/tap semantics
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      final fabSemantics = tester.getSemantics(fab);
      expect(fabSemantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      // 5. Meets minimum touch target guidelines for iOS (44x44)
      final handle = tester.ensureSemantics();
      expect(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('MonthStartsOnPage day chips expose accessible button & selected semantics', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          settingsProvider.overrideWith(
            (ref) => Stream.value(
              AppSettings.defaults.copyWith(monthStartDay: 10),
            ),
          ),
        ],
        home: const MonthStartsOnPage(),
      );
      await tester.pumpAndSettle();

      // Day 10 is selected and marked as selected button
      final day10Finder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '10' &&
            w.properties.selected == true,
      );
      expect(day10Finder, findsOneWidget);
      final day10Semantics = tester.getSemantics(day10Finder);
      expect(day10Semantics.flagsCollection.isButton, isTrue);
      expect(day10Semantics.flagsCollection.isSelected.toString(), 'Tristate.isTrue');

      // Day 1 is unselected button
      final day1Finder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '1' &&
            w.properties.selected == false,
      );
      expect(day1Finder, findsOneWidget);
      final day1Semantics = tester.getSemantics(day1Finder);
      expect(day1Semantics.flagsCollection.isButton, isTrue);
      expect(day1Semantics.flagsCollection.isSelected.toString(), isNot('Tristate.isTrue'));

      // Touch target guideline
      final handle = tester.ensureSemantics();
      expect(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('SettingsPage preference rows expose button semantics', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          settingsProvider.overrideWith(
            (ref) => Stream.value(AppSettings.defaults),
          ),
        ],
        home: const SettingsPage(),
      );
      await tester.pumpAndSettle();

      // Month starts on row is interactive and acts as a button
      final monthRow = find.ancestor(
        of: find.text('Month starts on'),
        matching: find.byType(InkWell),
      );
      expect(monthRow, findsOneWidget);
      final rowSemantics = tester.getSemantics(monthRow);
      expect(rowSemantics.flagsCollection.isButton, isTrue);
    });
  });
}

class _FakeCalendarNotifier extends CalendarNotifier {
  _FakeCalendarNotifier(this._initialState);
  final CalendarState _initialState;

  @override
  CalendarState build() => _initialState;
}
