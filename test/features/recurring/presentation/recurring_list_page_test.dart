import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/month_day_picker_page.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/presentation/pages/recurring_form_page.dart';
import 'package:ledgerly/features/recurring/presentation/pages/recurring_list_page.dart';
import 'package:ledgerly/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:ledgerly/features/recurring/presentation/widgets/recurring_item_card.dart';
import 'package:ledgerly/features/recurring/presentation/widgets/recurring_pending_banner.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

void main() {
  const testCategory = Category(
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

  final activeRecurring = RecurringTransaction(
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

  final dueManualRecurring = RecurringTransaction(
    id: 'rec-gym',
    categoryId: 'cat-subs',
    amount: const Money.minor(5000, CurrencyCode.usd),
    direction: TransactionDirection.expense,
    frequency: RecurringFrequency.monthly,
    startDate: LocalDate(2026, 1, 1),
    nextDueDate: LocalDate(2026, 10, 1), // due in the past/today
    autoAdd: false, // manual confirmation
    note: 'Gym Membership',
    isArchived: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  group('RecurringListPage', () {
    testWidgets('renders empty state when there are no recurring rules', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          recurringListStreamProvider.overrideWith(
            (ref) => Stream.value(const <RecurringTransaction>[]),
          ),
          currencyProvider.overrideWith((ref) => CurrencyCode.usd),
        ],
        home: const RecurringListPage(),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recurring Transactions'), findsOneWidget);
      expect(find.text('No recurring transactions'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('renders active recurring items and pending banner', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          recurringListStreamProvider.overrideWith(
            (ref) => Stream.value([activeRecurring, dueManualRecurring]),
          ),
          categoryByIdProvider('cat-subs')
              .overrideWith((ref) => Future.value(testCategory)),
          currencyProvider.overrideWith((ref) => CurrencyCode.usd),
        ],
        home: const RecurringListPage(),
      );

      await tester.pumpAndSettle();

      // Pending banner appears for due manual item
      expect(find.byType(RecurringPendingBanner), findsOneWidget);
      expect(find.text('Pending recurring transactions'), findsOneWidget);

      // Recurring item cards rendered
      expect(find.byType(RecurringItemCard), findsNWidgets(2));
      expect(find.text('Netflix 4K'), findsOneWidget);
      expect(find.text('Gym Membership'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('RecurringFormPage', () {
    testWidgets('renders create form fields with defaults', (tester) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          pickableCategoriesProvider(CategoryKind.expense)
              .overrideWith((ref) => Stream.value([testCategory])),
          currencyProvider.overrideWith((ref) => CurrencyCode.usd),
        ],
        home: const RecurringFormPage(),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Recurring'), findsOneWidget);
      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('Set an end date'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('opens the date picker from the start-date row', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (context, state) => const RecurringFormPage(),
          ),
          GoRoute(
            path: '/pickers/date',
            name: 'transactionDatePicker',
            builder: (context, state) => MonthDayPickerPage(
              initialDate: LocalDate.fromPacked(
                int.parse(state.uri.queryParameters['date']!),
              )!,
              firstDate: LocalDate(2000, 1, 1),
              lastDate: LocalDate(2100, 12, 31),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await pumpAppHost(
        tester,
        router: router,
        overrides: <Override>[
          pickableCategoriesProvider(CategoryKind.expense)
              .overrideWith((ref) => Stream.value([testCategory])),
          currencyProvider.overrideWith((ref) => CurrencyCode.usd),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Date'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthDayPickerPage), findsOneWidget);
      expect(find.text('Monthly'), findsNothing);

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.byType(MonthDayPickerPage), findsNothing);

      await tester.tap(find.text('Set an end date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End Date'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthDayPickerPage), findsOneWidget);
    });
  });
}
