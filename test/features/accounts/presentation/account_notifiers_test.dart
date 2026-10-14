import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_type.dart';
import 'package:ledgerly/features/accounts/domain/usecases/delete_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/reorder_accounts.dart';
import 'package:ledgerly/features/accounts/domain/usecases/save_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/set_account_archived.dart';
import 'package:ledgerly/features/accounts/domain/usecases/transfer_between_accounts.dart';
import 'package:ledgerly/features/accounts/domain/validators/account_validators.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';

import '../domain/account_usecases_test.dart';

void main() {
  late FakeAccountRepository repo;
  late ProviderContainer container;

  const testAccount = Account(
    id: 'acc-1',
    name: 'Cash Wallet',
    type: AccountType.cash,
    currency: CurrencyCode.mmk,
    openingBalanceMinor: 50000,
    currentBalanceMinor: 50000,
    iconKey: 'wallet',
    colorValue: 0xFF2E7D6B,
    sortOrder: 0,
    isArchived: false,
    includeInTotal: true,
    createdAt: 1000,
    updatedAt: 1000,
  );

  setUp(() {
    repo = FakeAccountRepository();
    container = ProviderContainer(
      overrides: <Override>[
        saveAccountUseCaseProvider.overrideWithValue(SaveAccount(repo)),
        deleteAccountUseCaseProvider.overrideWithValue(DeleteAccount(repo)),
        setAccountArchivedUseCaseProvider.overrideWithValue(
          SetAccountArchived(repo),
        ),
        reorderAccountsUseCaseProvider.overrideWithValue(ReorderAccounts(repo)),
        transferBetweenAccountsUseCaseProvider.overrideWithValue(
          TransferBetweenAccounts(repo),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AccountFormNotifier', () {
    test('initialise with null creates blank form state', () {
      final notifier = container.read(accountFormNotifierProvider.notifier);
      notifier.initialise();
      final state = container.read(accountFormNotifierProvider);

      expect(state.name, isEmpty);
      expect(state.type, AccountType.cash);
      expect(state.openingBalanceMinor, 0);
      expect(state.includeInTotal, isTrue);
      expect(state.isEditing, isFalse);
    });

    test('initialise with existing account populates form state', () {
      final notifier = container.read(accountFormNotifierProvider.notifier);
      notifier.initialise(existing: testAccount);
      final state = container.read(accountFormNotifierProvider);

      expect(state.name, 'Cash Wallet');
      expect(state.type, AccountType.cash);
      expect(state.currency, CurrencyCode.mmk);
      expect(state.openingBalanceMinor, 50000);
      expect(state.existingId, 'acc-1');
      expect(state.isEditing, isTrue);
    });

    test('field setters update state correctly', () {
      final notifier = container.read(accountFormNotifierProvider.notifier);
      notifier.setName('KBZ Pay');
      notifier.setType(AccountType.ewallet);
      notifier.setCurrency(CurrencyCode.usd);
      notifier.setOpeningBalance(1000);
      notifier.setIcon('phone_android');
      notifier.setColor(0xFF3A8FE8);
      notifier.setIncludeInTotal(false);

      final state = container.read(accountFormNotifierProvider);
      expect(state.name, 'KBZ Pay');
      expect(state.type, AccountType.ewallet);
      expect(state.currency, CurrencyCode.usd);
      expect(state.openingBalanceMinor, 1000);
      expect(state.iconKey, 'phone_android');
      expect(state.colorValue, 0xFF3A8FE8);
      expect(state.includeInTotal, isFalse);
    });

    test('save fails on empty name', () async {
      final notifier = container.read(accountFormNotifierProvider.notifier);
      notifier.initialise();
      notifier.setName('   ');

      final success = await notifier.save();
      expect(success, isFalse);

      final state = container.read(accountFormNotifierProvider);
      expect(state.fieldErrors['name'], AccountValidators.nameRequired);
    });

    test('save succeeds on valid account', () async {
      final notifier = container.read(accountFormNotifierProvider.notifier);
      notifier.initialise();
      notifier.setName('Savings Account');
      notifier.setType(AccountType.savings);
      notifier.setOpeningBalance(200000);

      final success = await notifier.save();
      expect(success, isTrue);

      final state = container.read(accountFormNotifierProvider);
      expect(state.saved, isTrue);
      expect(
        repo.accounts.values.any((a) => a.name == 'Savings Account'),
        isTrue,
      );
    });
  });

  group('TransferNotifier', () {
    test('initialise sets default accounts and date', () {
      final notifier = container.read(transferNotifierProvider.notifier);
      notifier.initialise(defaultFromId: 'acc-1', defaultToId: 'acc-2');

      final state = container.read(transferNotifierProvider);
      expect(state.fromAccountId, 'acc-1');
      expect(state.toAccountId, 'acc-2');
      expect(state.amountMinor, 0);
      expect(state.isSuccess, isFalse);
    });

    test('field setters update transfer state', () {
      final notifier = container.read(transferNotifierProvider.notifier);
      final date = LocalDate(2026, 10, 15);

      notifier.setFromAccount('from-1');
      notifier.setToAccount('to-2');
      notifier.setAmount(5000);
      notifier.setDate(date);
      notifier.setNote('Dinner refund');

      final state = container.read(transferNotifierProvider);
      expect(state.fromAccountId, 'from-1');
      expect(state.toAccountId, 'to-2');
      expect(state.amountMinor, 5000);
      expect(state.date, date);
      expect(state.note, 'Dinner refund');
    });

    test('submit rejects same account transfer', () async {
      final notifier = container.read(transferNotifierProvider.notifier);
      notifier.setFromAccount('acc-same');
      notifier.setToAccount('acc-same');
      notifier.setAmount(1000);

      final success = await notifier.submit(currency: CurrencyCode.mmk);
      expect(success, isFalse);

      final state = container.read(transferNotifierProvider);
      expect(
        state.fieldErrors['transfer'],
        AccountValidators.transferSameAccount,
      );
    });

    test('submit rejects non-positive amount', () async {
      final notifier = container.read(transferNotifierProvider.notifier);
      notifier.setFromAccount('acc-1');
      notifier.setToAccount('acc-2');
      notifier.setAmount(0);

      final success = await notifier.submit(currency: CurrencyCode.mmk);
      expect(success, isFalse);

      final state = container.read(transferNotifierProvider);
      expect(
        state.fieldErrors['transfer'],
        AccountValidators.transferAmountInvalid,
      );
    });

    test('submit executes valid transfer successfully', () async {
      final notifier = container.read(transferNotifierProvider.notifier);
      notifier.setFromAccount('acc-1');
      notifier.setToAccount('acc-2');
      notifier.setAmount(10000);
      notifier.setNote('Bank transfer');

      final success = await notifier.submit(currency: CurrencyCode.mmk);
      expect(success, isTrue);

      final state = container.read(transferNotifierProvider);
      expect(state.isSuccess, isTrue);
      expect(repo.transfers.length, 1);
      expect(repo.transfers.first.amount.amountMinor, 10000);
    });
  });

  group('AccountActionNotifier', () {
    test('deleteAccount calls delete usecase', () async {
      await repo.saveAccount(account: testAccount, isNew: true);
      expect(repo.accounts.length, 1);

      final notifier = container.read(accountActionNotifierProvider.notifier);
      final success = await notifier.deleteAccount('acc-1');
      expect(success, isTrue);
      expect(repo.accounts['acc-1']!.isDeleted, isTrue);
    });

    test('setArchived toggles account archive status', () async {
      await repo.saveAccount(account: testAccount, isNew: true);

      final notifier = container.read(accountActionNotifierProvider.notifier);
      final success = await notifier.setArchived('acc-1', true);
      expect(success, isTrue);
      expect(repo.accounts['acc-1']!.isArchived, isTrue);
    });

    test('reorder updates account sort orders', () async {
      await repo.saveAccount(account: testAccount, isNew: true);
      final second = testAccount.copyWith(id: 'acc-2', name: 'Bank');
      await repo.saveAccount(account: second, isNew: true);

      final notifier = container.read(accountActionNotifierProvider.notifier);
      final success = await notifier.reorder(['acc-2', 'acc-1']);
      expect(success, isTrue);
      expect(repo.accounts['acc-2']!.sortOrder, 0);
      expect(repo.accounts['acc-1']!.sortOrder, 1);
    });
  });
}
