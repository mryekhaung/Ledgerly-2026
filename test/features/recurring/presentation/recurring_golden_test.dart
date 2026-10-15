import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/presentation/pages/recurring_list_page.dart';
import 'package:ledgerly/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';
import '../../../support/width_walk.dart';

/// The recurring list screen, compact, light + dark (`docs/Design.md` §8).
///
/// Both lists and the category lookup are seeded: with no overrides the page
/// resolves against unregistered DI and pins an error banner instead of the
/// rows. Every `nextDueDate` is in the future, so the pending banner stays out
/// of the picture and the golden shows the ordinary list.
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('recurring_golden_test.dart'));

  const subscriptions = Category(
    id: 'cat-subs',
    name: 'Subscriptions',
    iconKey: 'subscriptions',
    colorValue: 0xFF3B82F6,
    kind: CategoryKind.expense,
    sortOrder: 0,
    isDefault: true,
    isArchived: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  final netflix = RecurringTransaction(
    id: 'rec-netflix',
    categoryId: 'cat-subs',
    amount: const Money.minor(1500, CurrencyCode.usd),
    direction: TransactionDirection.expense,
    frequency: RecurringFrequency.monthly,
    startDate: LocalDate(2026, 1, 1),
    nextDueDate: LocalDate(2026, 11, 1),
    autoAdd: true,
    note: 'Netflix 4K',
    isArchived: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  final gym = RecurringTransaction(
    id: 'rec-gym',
    categoryId: 'cat-subs',
    amount: const Money.minor(5000, CurrencyCode.usd),
    direction: TransactionDirection.expense,
    frequency: RecurringFrequency.monthly,
    startDate: LocalDate(2026, 1, 1),
    nextDueDate: LocalDate(2026, 11, 5),
    autoAdd: true,
    note: 'Gym Membership',
    isArchived: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  final pausedCloud = RecurringTransaction(
    id: 'rec-cloud',
    categoryId: 'cat-subs',
    amount: const Money.minor(999, CurrencyCode.usd),
    direction: TransactionDirection.expense,
    frequency: RecurringFrequency.yearly,
    startDate: LocalDate(2026, 3, 1),
    nextDueDate: LocalDate(2027, 3, 1),
    autoAdd: false,
    note: 'Cloud storage',
    isArchived: true,
    createdAt: 1000,
    updatedAt: 1000,
  );

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double width = TestWidths.phone,
    double textScale = 1,
  }) => pumpAppHost(
    tester,
    size: Size(width, 900),
    brightness: brightness,
    textScaler: TextScaler.linear(textScale),
    overrides: <Override>[
      recurringListStreamProvider.overrideWith(
        (ref) =>
            Stream.value(<RecurringTransaction>[netflix, gym, pausedCloud]),
      ),
      categoryByIdProvider('cat-subs')
          .overrideWith((ref) => Future<Category>.value(subscriptions)),
      currencyProvider.overrideWith((ref) => CurrencyCode.usd),
    ],
    home: const RecurringListPage(),
  );

  widthWalkGroup(pageName: 'RecurringListPage', host: host);

  group('Recurring screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RecurringListPage),
        matchesGoldenFile('goldens/recurring_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RecurringListPage),
        matchesGoldenFile('goldens/recurring_dark.png'),
      );
    });
  });
}
