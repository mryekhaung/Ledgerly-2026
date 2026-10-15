import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_type.dart';
import 'package:ledgerly/features/accounts/presentation/pages/accounts_page.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';
import '../../../support/width_walk.dart';

/// The accounts screen, compact, light + dark (`docs/Design.md` §8).
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('accounts_golden_test.dart'));

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
      accountsStreamProvider.overrideWith(
        (ref) => Stream.value(const <Account>[account1, account2]),
      ),
      archivedAccountsStreamProvider.overrideWith(
        (ref) => Stream.value(const <Account>[]),
      ),
      totalNetWorthProvider.overrideWithValue(575000),
    ],
    home: const AccountsPage(),
  );

  widthWalkGroup(pageName: 'AccountsPage', host: host);

  group('Accounts screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AccountsPage),
        matchesGoldenFile('goldens/accounts_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AccountsPage),
        matchesGoldenFile('goldens/accounts_dark.png'),
      );
    });
  });
}
