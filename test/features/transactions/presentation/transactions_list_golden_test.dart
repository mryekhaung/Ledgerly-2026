import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/search_transactions.dart';
import 'package:ledgerly/features/transactions/presentation/pages/transactions_list_page.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';
import '../../categories/domain/fake_category_repository.dart';
import '../domain/fake_transaction_repository.dart';

/// The transactions list screen, compact, light + dark (`docs/Design.md` §8).
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('transactions_list_golden_test.dart'));

  final day = LocalDate(2026, 10, 5);

  final categories = <Category>[
    fakeCategory(id: 'cat-food', name: 'Food & Dining'),
    fakeCategory(id: 'cat-salary', name: 'Salary'),
  ];

  List<Transaction> seedTransactions() => <Transaction>[
    fakeTransaction(
      id: 'txn-1',
      categoryId: 'cat-food',
      amountMinor: 4500,
      direction: TransactionDirection.expense,
      date: day,
      note: 'Morning coffee',
    ),
    fakeTransaction(
      id: 'txn-2',
      categoryId: 'cat-salary',
      amountMinor: 750000,
      direction: TransactionDirection.income,
      date: day,
      note: 'Monthly salary',
    ),
  ];

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) {
    final fakeRepo = FakeTransactionRepository(seed: seedTransactions());

    return pumpAppHost(
      tester,
      size: const Size(TestWidths.phone, 900),
      brightness: brightness,
      overrides: <Override>[
        searchTransactionsProvider.overrideWithValue(
          SearchTransactions(fakeRepo),
        ),
        deleteTransactionProvider.overrideWithValue(
          DeleteTransaction(fakeRepo),
        ),
        restoreTransactionProvider.overrideWithValue(
          RestoreTransaction(fakeRepo),
        ),
        categoryByIdProvider.overrideWith(
          (ref, id) async => categories.firstWhere((c) => c.id == id),
        ),
        currencyProvider.overrideWithValue(CurrencyCode.mmk),
      ],
      home: const TransactionsListPage(),
    );
  }

  group('Transactions list screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TransactionsListPage),
        matchesGoldenFile('goldens/transactions_list_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TransactionsListPage),
        matchesGoldenFile('goldens/transactions_list_dark.png'),
      );
    });
  });
}
