import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:ledgerly/features/transactions/presentation/pages/calendar_page.dart';
import 'package:ledgerly/features/transactions/presentation/providers/calendar_notifier.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../categories/domain/fake_category_repository.dart';
import '../domain/fake_transaction_repository.dart';

/// Tolerant comparator allowing minor rasterizer differences across OSes.
class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile, {this.tolerance = 0.02});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent > tolerance) {
      final error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return result.passed || result.diffPercent <= tolerance;
  }
}

/// The calendar screen, compact, light + dark (`docs/Design.md` §8).
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() {
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenComparator(
      Uri.parse('${current.basedir}calendar_golden_test.dart'),
      tolerance: 0.02,
    );
  });

  /// A month with a couple of days that have activity.
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

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) {
    final fakes = FakeTransactionRepository(seed: dayTransactions());

    return pumpAppHost(
      tester,
      size: const Size(TestWidths.phone, 900),
      brightness: brightness,
      overrides: <Override>[
        watchDayTransactionsProvider.overrideWithValue(
          WatchDayTransactions(fakes),
        ),
        watchPeriodDailyTotalsProvider.overrideWithValue(
          WatchPeriodDailyTotals(fakes),
        ),
        watchDayTotalProvider.overrideWithValue(WatchDayTotal(fakes)),
        watchPeriodTotalProvider.overrideWithValue(WatchPeriodTotal(fakes)),
        categoryByIdProvider.overrideWith(
          (ref, id) async => categories.firstWhere((c) => c.id == id),
        ),
        currencyProvider.overrideWithValue(CurrencyCode.mmk),
        weekStartProvider.overrideWithValue(WeekStart.monday),
        calendarProvider.overrideWith(() => _SeededCalendarNotifier(day)),
      ],
      home: const CalendarPage(),
    );
  }

  group('Calendar screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CalendarPage),
        matchesGoldenFile('goldens/calendar_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CalendarPage),
        matchesGoldenFile('goldens/calendar_dark.png'),
      );
    });
  });
}

/// A [CalendarNotifier] pinned to a fixed day rather than the real "today".
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
