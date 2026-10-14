import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/category_list_state.dart';
import 'package:ledgerly/features/categories/presentation/pages/category_list_page.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_list_notifier.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
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
  group('Screen Lifecycle & Memory Profiling', () {
    final today = LocalDate.fromDateTime(DateTime.now());
    final period = BudgetPeriod(
      start: today.firstDayOfMonth,
      end: LocalDate(
        today.year,
        today.month,
        LocalDate.daysInMonth(today.year, today.month),
      ),
    );

    final overrides = <Override>[
      settingsProvider.overrideWith((_) => Stream.value(AppSettings.defaults)),
      currencyProvider.overrideWithValue(CurrencyCode.usd),
      monthStartDayProvider.overrideWithValue(1),
      userProfileProvider.overrideWith(
        (_) => Stream.value(UserProfile.initial),
      ),
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
      categoryListProvider.overrideWith(
        () => _FixedCategoryListNotifier(
          CategoryListState.of(const <Category>[]),
        ),
      ),
    ];

    testWidgets(
      'Navigating push and pop across screens 10x produces zero leaks or errors',
      (tester) async {
        await pumpAppHost(
          tester,
          overrides: overrides,
          size: const Size(400, 800),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ElevatedButton(
                      key: const ValueKey('goto_calendar'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CalendarPage(),
                          ),
                        );
                      },
                      child: const Text('Calendar'),
                    ),
                    ElevatedButton(
                      key: const ValueKey('goto_settings'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                      child: const Text('Settings'),
                    ),
                    ElevatedButton(
                      key: const ValueKey('goto_month_starts'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MonthStartsOnPage(),
                          ),
                        );
                      },
                      child: const Text('Month Starts'),
                    ),
                    ElevatedButton(
                      key: const ValueKey('goto_categories'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CategoryListPage(),
                          ),
                        );
                      },
                      child: const Text('Categories'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (var i = 0; i < 10; i++) {
          // Push CalendarPage and pop
          await tester.tap(find.byKey(const ValueKey('goto_calendar')));
          await tester.pumpAndSettle();
          expect(find.byType(CalendarPage), findsOneWidget);
          Navigator.of(tester.element(find.byType(CalendarPage))).pop();
          await tester.pumpAndSettle();
          expect(find.byType(CalendarPage), findsNothing);

          // Push SettingsPage and pop
          await tester.tap(find.byKey(const ValueKey('goto_settings')));
          await tester.pumpAndSettle();
          expect(find.byType(SettingsPage), findsOneWidget);
          Navigator.of(tester.element(find.byType(SettingsPage))).pop();
          await tester.pumpAndSettle();
          expect(find.byType(SettingsPage), findsNothing);

          // Push MonthStartsOnPage and pop
          await tester.tap(find.byKey(const ValueKey('goto_month_starts')));
          await tester.pumpAndSettle();
          expect(find.byType(MonthStartsOnPage), findsOneWidget);
          Navigator.of(tester.element(find.byType(MonthStartsOnPage))).pop();
          await tester.pumpAndSettle();
          expect(find.byType(MonthStartsOnPage), findsNothing);

          // Push CategoryListPage and pop
          await tester.tap(find.byKey(const ValueKey('goto_categories')));
          await tester.pumpAndSettle();
          expect(find.byType(CategoryListPage), findsOneWidget);
          Navigator.of(tester.element(find.byType(CategoryListPage))).pop();
          await tester.pumpAndSettle();
          expect(find.byType(CategoryListPage), findsNothing);

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Screen rotation across portrait and landscape 10x preserves clean lifecycle',
      (tester) async {
        await pumpAppHost(
          tester,
          overrides: overrides,
          size: const Size(390, 844),
          home: const CalendarPage(),
        );
        await tester.pumpAndSettle();

        for (var i = 0; i < 10; i++) {
          // Rotate to Landscape
          tester.view.physicalSize = const Size(844, 390);
          tester.view.devicePixelRatio = 1.0;
          await tester.pumpAndSettle();
          expect(find.byType(CalendarPage), findsOneWidget);

          // Rotate back to Portrait
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1.0;
          await tester.pumpAndSettle();
          expect(find.byType(CalendarPage), findsOneWidget);

          expect(tester.takeException(), isNull);
        }

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      },
    );
  });
}

class _FakeCalendarNotifier extends CalendarNotifier {
  _FakeCalendarNotifier(this._initialState);
  final CalendarState _initialState;

  @override
  CalendarState build() => _initialState;
}

class _FixedCategoryListNotifier extends CategoryListNotifier {
  _FixedCategoryListNotifier(this._initial);
  final CategoryListState _initial;

  @override
  Stream<CategoryListState> build() =>
      Stream<CategoryListState>.value(_initial);
}
