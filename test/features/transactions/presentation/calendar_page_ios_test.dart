import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:ledgerly/features/transactions/presentation/pages/calendar_page.dart';
import 'package:ledgerly/features/transactions/presentation/providers/calendar_notifier.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/calendar_grid_fixture.dart';
import '../domain/fake_transaction_repository.dart';

void main() {
  testWidgets(
    'CalendarPage on iOS with transactions renders rows without throwing',
    (tester) async {
      final day = LocalDate(2026, 10, 3);
      final txns = <Transaction>[
        fakeTransaction(
          id: 'txn-1',
          categoryId: 'cat-food',
          amountMinor: 5000,
          date: day,
          note: 'Coffee',
        ),
      ];
      final fakes = FakeTransactionRepository(seed: txns);

      await pumpAppHost(
        tester,
        size: const Size(390, 844),
        platform: AppPlatform.ios,
        home: const CalendarPage(),
        overrides: [
          watchDayTransactionsProvider.overrideWithValue(
            WatchDayTransactions(fakes),
          ),
          watchPeriodDailyTotalsProvider.overrideWithValue(
            WatchPeriodDailyTotals(fakes),
          ),
          watchDayTotalProvider.overrideWithValue(WatchDayTotal(fakes)),
          watchPeriodTotalProvider.overrideWithValue(WatchPeriodTotal(fakes)),
          categoryByIdProvider.overrideWith(
            (ref, id) async =>
                calendarGridCategories.firstWhere((c) => c.id == id),
          ),
          currencyProvider.overrideWithValue(CurrencyCode.mmk),
          weekStartProvider.overrideWithValue(WeekStart.monday),
          calendarProvider.overrideWith(() => _SeededCalendarNotifier(day)),
        ],
      );

      await tester.pumpAndSettle();
      final scaffold = tester.widget<AppScaffold>(find.byType(AppScaffold));
      expect(scaffold.adaptiveActions, hasLength(2));
      expect(scaffold.adaptiveActions?[0].iosSymbol, 'magnifyingglass');
      expect(scaffold.adaptiveActions?[1].title, 'Today');

      // Scroll to reveal the rows
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Coffee'), findsOneWidget);
    },
  );
}

class _SeededCalendarNotifier extends CalendarNotifier {
  _SeededCalendarNotifier(this._day);
  final LocalDate _day;
  @override
  CalendarState build() {
    return CalendarState(selectedDay: _day, isTodaySelected: false);
  }
}
