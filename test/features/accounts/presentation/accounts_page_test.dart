import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveTabBarView;
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_type.dart';
import 'package:ledgerly/features/accounts/presentation/pages/account_form_page.dart';
import 'package:ledgerly/features/accounts/presentation/pages/accounts_page.dart';
import 'package:ledgerly/features/accounts/presentation/pages/transfer_page.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/accounts/presentation/widgets/account_card.dart';
import 'package:ledgerly/features/accounts/presentation/widgets/net_worth_card.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

void main() {
  const account1 = Account(
    id: 'acc-1',
    name: 'Cash Wallet',
    type: AccountType.cash,
    currency: CurrencyCode.mmk,
    openingBalanceMinor: 50000,
    currentBalanceMinor: 75000,
    iconKey: 'wallet',
    colorValue: 0xFF2E7D6B,
    sortOrder: 0,
    isArchived: false,
    includeInTotal: true,
    createdAt: 1000,
    updatedAt: 1000,
  );

  const account2 = Account(
    id: 'acc-2',
    name: 'KBZ Bank',
    type: AccountType.bank,
    currency: CurrencyCode.mmk,
    openingBalanceMinor: 200000,
    currentBalanceMinor: 500000,
    iconKey: 'account_balance',
    colorValue: 0xFF1976D2,
    sortOrder: 1,
    isArchived: false,
    includeInTotal: true,
    createdAt: 1000,
    updatedAt: 1000,
  );

  const archivedAccount = Account(
    id: 'acc-archived',
    name: 'Old Bank Account',
    type: AccountType.bank,
    currency: CurrencyCode.mmk,
    openingBalanceMinor: 0,
    currentBalanceMinor: 0,
    iconKey: 'account_balance',
    colorValue: 0xFF757575,
    sortOrder: 2,
    isArchived: true,
    includeInTotal: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  group('AccountsPage', () {
    testWidgets('renders empty state when there are no active accounts', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          accountsStreamProvider.overrideWith(
            (ref) => Stream.value(const <Account>[]),
          ),
          archivedAccountsStreamProvider.overrideWith(
            (ref) => Stream.value(const <Account>[]),
          ),
          totalNetWorthProvider.overrideWithValue(0),
        ],
        home: const AccountsPage(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveTabBarView), findsOneWidget);
      expect(find.text('No accounts yet'), findsOneWidget);
    });

    testWidgets('renders account cards when active accounts exist', (
      tester,
    ) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          accountsStreamProvider.overrideWith(
            (ref) => Stream.value(<Account>[account1, account2]),
          ),
          archivedAccountsStreamProvider.overrideWith(
            (ref) => Stream.value(const <Account>[]),
          ),
          totalNetWorthProvider.overrideWithValue(575000),
        ],
        home: const AccountsPage(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NetWorthCard), findsOneWidget);
      expect(find.byType(AccountCard), findsNWidgets(2));
      expect(find.text('Cash Wallet'), findsOneWidget);
      expect(find.text('KBZ Bank'), findsOneWidget);
    });

    testWidgets('renders archived accounts on Archived tab', (tester) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          accountsStreamProvider.overrideWith(
            (ref) => Stream.value(<Account>[account1]),
          ),
          archivedAccountsStreamProvider.overrideWith(
            (ref) => Stream.value(<Account>[archivedAccount]),
          ),
          totalNetWorthProvider.overrideWithValue(75000),
        ],
        home: const AccountsPage(),
      );
      await tester.pumpAndSettle();

      // Switch to Archived tab
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      expect(find.text('Old Bank Account'), findsOneWidget);
    });
  });

  group('AccountFormPage', () {
    testWidgets('renders create form correctly', (tester) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          currencyProvider.overrideWithValue(CurrencyCode.mmk),
        ],
        home: const AccountFormPage(),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Account'), findsOneWidget);
      final visibleField = find.byType(TextField, skipOffstage: false);
      expect(tester.widget<TextField>(visibleField).controller?.text, isEmpty);
      expect(visibleField, findsOneWidget);
    });

    testWidgets('renders edit form correctly', (tester) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          currencyProvider.overrideWithValue(CurrencyCode.mmk),
          accountByIdProvider('acc-1')
              .overrideWith((ref) => Future.value(account1)),
        ],
        home: const AccountFormPage(accountId: 'acc-1'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Account'), findsOneWidget);
      expect(find.text('Cash Wallet', skipOffstage: false), findsNWidgets(2));
    });
  });

  group('TransferPage', () {
    testWidgets('renders transfer form with account selectors', (tester) async {
      await pumpAppHost(
        tester,
        overrides: <Override>[
          currencyProvider.overrideWithValue(CurrencyCode.mmk),
          accountsStreamProvider.overrideWith(
            (ref) => Stream.value(<Account>[account1, account2]),
          ),
        ],
        home: const TransferPage(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transfer Funds'), findsOneWidget);
      expect(find.text('From Account', skipOffstage: false), findsOneWidget);
      expect(find.text('To Account', skipOffstage: false), findsOneWidget);
    });
  });
}
