import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/accounts/data/datasources/account_local_datasource.dart';
import 'package:ledgerly/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_transfer.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_type.dart';

import '../../../core/database/db_harness.dart';

void main() {
  group('AccountRepositoryImpl with real SQLite', () {
    late DbHarness harness;
    late AccountLocalDataSource datasource;
    late AccountRepositoryImpl repository;

    setUp(() async {
      harness = useDbHarness();
      datasource = AccountLocalDataSource(harness.db);
      repository = AccountRepositoryImpl(datasource);
    });

    const testAccount = Account(
      id: 'acc-wallet',
      name: 'Cash Wallet',
      type: AccountType.cash,
      currency: CurrencyCode.mmk,
      openingBalanceMinor: 10000000, // 100,000 MMK
      currentBalanceMinor: 10000000,
      iconKey: 'wallet',
      colorValue: 0xFF5A8FE8,
      sortOrder: 0,
      isArchived: false,
      includeInTotal: true,
      createdAt: 1000,
      updatedAt: 1000,
    );

    test('saveAccount inserts, reads, and updates accounts', () async {
      final insertRes = await repository.saveAccount(
        account: testAccount,
        isNew: true,
      );
      expect(insertRes.isSuccess, isTrue);

      final readRes = await repository.getAccount('acc-wallet');
      expect(readRes.isSuccess, isTrue);
      expect(readRes.valueOrNull?.name, 'Cash Wallet');
      expect(readRes.valueOrNull?.currentBalanceMinor, 10000000);

      // Update name
      final updated = testAccount.copyWith(name: 'Main Wallet');
      final updateRes = await repository.saveAccount(
        account: updated,
        isNew: false,
      );
      expect(updateRes.isSuccess, isTrue);
      expect(
        (await repository.getAccount('acc-wallet')).valueOrNull?.name,
        'Main Wallet',
      );
    });

    test('deleteAccount and setAccountArchived update flags', () async {
      await repository.saveAccount(account: testAccount, isNew: true);

      // Archive
      await repository.setAccountArchived('acc-wallet', true);
      expect(
        (await repository.getAccount('acc-wallet')).valueOrNull?.isArchived,
        isTrue,
      );

      // Delete
      await repository.deleteAccount('acc-wallet');
      final deleted = await repository.getAccount('acc-wallet');
      expect(deleted.isErr, isTrue);
    });

    test('transferFunds moves money atomically between two accounts', () async {
      const accA = testAccount;
      final accB = testAccount.copyWith(
        id: 'acc-bank',
        name: 'KBZ Bank',
        type: AccountType.bank,
        openingBalanceMinor: 5000000, // 50,000 MMK
        currentBalanceMinor: 5000000,
      );

      await repository.saveAccount(account: accA, isNew: true);
      await repository.saveAccount(account: accB, isNew: true);

      // Transfer 20,000 MMK from Wallet to Bank
      final transferRes = await repository.transferFunds(
        AccountTransfer(
          fromAccountId: 'acc-wallet',
          toAccountId: 'acc-bank',
          amount: const Money.minor(2000000, CurrencyCode.mmk),
          date: LocalDate(2026, 10, 14),
          note: 'Bank deposit',
        ),
      );
      expect(transferRes.isSuccess, isTrue);

      // Wallet balance: 100,000 - 20,000 = 80,000 MMK
      final wallet = (await repository.getAccount('acc-wallet')).valueOrNull!;
      expect(wallet.currentBalanceMinor, 8000000);

      // Bank balance: 50,000 + 20,000 = 70,000 MMK
      final bank = (await repository.getAccount('acc-bank')).valueOrNull!;
      expect(bank.currentBalanceMinor, 7000000);

      // Sum of both balances is still 150,000 MMK (invariant preserved)
      expect(wallet.currentBalanceMinor + bank.currentBalanceMinor, 15000000);
    });
  });
}
