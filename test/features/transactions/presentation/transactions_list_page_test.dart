import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/search_transactions.dart';
import 'package:ledgerly/features/transactions/presentation/pages/transactions_list_page.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/transaction_filter_sheet.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../categories/domain/fake_category_repository.dart';
import '../domain/fake_transaction_repository.dart';

void main() {
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
    FakeTransactionRepository? repository,
  }) {
    final fakeRepo =
        repository ?? FakeTransactionRepository(seed: seedTransactions());

    return pumpAppHost(
      tester,
      size: const Size(400, 800),
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

  group('TransactionsListPage', () {
    testWidgets(
      'renders search field, direction filter chips, and transaction rows',
      (tester) async {
        await host(tester);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'Expense'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'Income'), findsOneWidget);

        expect(find.text('Morning coffee'), findsOneWidget);
        expect(find.text('Monthly salary'), findsOneWidget);
      },
    );

    testWidgets('filters by search text input with debounce', (tester) async {
      await host(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'coffee');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Morning coffee'), findsOneWidget);
      expect(find.text('Monthly salary'), findsNothing);

      // Clear search (the clear glyph comes from the AppIcons vocabulary).
      // Scoped to the field: an active search also reveals the "Clear all"
      // chip, which carries the same close glyph.
      final clearIcon = find.descendant(
        of: find.byType(TextField),
        matching: find.byIcon(AppIcons.close),
      );
      expect(clearIcon, findsOneWidget);
      await tester.tap(clearIcon);
      await tester.pumpAndSettle();

      expect(find.text('Morning coffee'), findsOneWidget);
      expect(find.text('Monthly salary'), findsOneWidget);
    });

    testWidgets('filters by direction chips', (tester) async {
      await host(tester);
      await tester.pumpAndSettle();

      // Tap Expense filter
      await tester.tap(find.widgetWithText(FilterChip, 'Expense'));
      await tester.pumpAndSettle();

      expect(find.text('Morning coffee'), findsOneWidget);
      expect(find.text('Monthly salary'), findsNothing);

      // Tap Income filter
      await tester.tap(find.widgetWithText(FilterChip, 'Income'));
      await tester.pumpAndSettle();

      expect(find.text('Morning coffee'), findsNothing);
      expect(find.text('Monthly salary'), findsOneWidget);

      // Tap All filter to reset
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('Morning coffee'), findsOneWidget);
      expect(find.text('Monthly salary'), findsOneWidget);
    });

    testWidgets('displays empty state when query returns no results', (
      tester,
    ) async {
      await host(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'non-existent-search');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byType(StatePlaceholder), findsOneWidget);
      expect(find.text('No transactions found'), findsOneWidget);
    });

    testWidgets('opens filter bottom sheet on tune button tap', (tester) async {
      await host(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.tune));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFilterSheet), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
    });

    testWidgets('swipe to delete removes item and allows undo', (tester) async {
      final fakeRepo = FakeTransactionRepository(seed: seedTransactions());
      await host(tester, repository: fakeRepo);
      await tester.pumpAndSettle();

      expect(find.text('Morning coffee'), findsOneWidget);

      // Swipe to delete
      await tester.drag(find.text('Morning coffee'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Morning coffee'), findsNothing);
      expect(find.text('Transaction deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(fakeRepo.restoredIds, contains('txn-1'));
      expect(find.text('Morning coffee'), findsOneWidget);
    });
  });
}
