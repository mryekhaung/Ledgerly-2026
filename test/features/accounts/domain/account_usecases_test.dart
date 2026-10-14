import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_transfer.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_type.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';
import 'package:ledgerly/features/accounts/domain/usecases/delete_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/get_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/reorder_accounts.dart';
import 'package:ledgerly/features/accounts/domain/usecases/save_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/set_account_archived.dart';
import 'package:ledgerly/features/accounts/domain/usecases/transfer_between_accounts.dart';
import 'package:ledgerly/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:ledgerly/features/accounts/domain/validators/account_validators.dart';

class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> accounts = {};
  final List<AccountTransfer> transfers = [];
  final StreamController<List<Account>> _controller =
      StreamController<List<Account>>.broadcast();

  AccountTransfer? lastTransfer;

  void emit() {
    _controller.add(accounts.values.toList());
  }

  @override
  Stream<Result<List<Account>>> watchAccounts({bool includeArchived = false}) {
    return _controller.stream.map((list) {
      final filtered = includeArchived
          ? list
          : list.where((a) => !a.isArchived && a.deletedAt == null).toList();
      return Success(filtered);
    });
  }

  @override
  Future<Result<Account>> getAccount(String id) async {
    final acc = accounts[id];
    if (acc == null || acc.deletedAt != null) {
      return const Err(NotFoundFailure('Account not found'));
    }
    return Success(acc);
  }

  @override
  Future<Result<Account>> saveAccount({
    required Account account,
    bool isNew = false,
  }) async {
    accounts[account.id] = account;
    emit();
    return Success(account);
  }

  @override
  Future<Result<void>> deleteAccount(String id) async {
    final acc = accounts[id];
    if (acc != null) {
      accounts[id] = acc.copyWith(deletedAt: 123456789);
      emit();
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> setAccountArchived(String id, bool isArchived) async {
    final acc = accounts[id];
    if (acc != null) {
      accounts[id] = acc.copyWith(isArchived: isArchived);
      emit();
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> reorderAccounts(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final acc = accounts[orderedIds[i]];
      if (acc != null) {
        accounts[orderedIds[i]] = acc.copyWith(sortOrder: i);
      }
    }
    emit();
    return const Success(null);
  }

  @override
  Future<Result<bool>> nameExists(String name, {String? excludingId}) async {
    final lowered = name.trim().toLowerCase();
    final exists = accounts.values.any(
      (a) =>
          a.id != excludingId &&
          a.deletedAt == null &&
          a.name.trim().toLowerCase() == lowered,
    );
    return Success(exists);
  }

  @override
  Future<Result<int>> calculateAccountBalance(String accountId) async {
    final acc = accounts[accountId];
    return Success(acc?.currentBalanceMinor ?? 0);
  }

  @override
  Future<Result<void>> transferFunds(AccountTransfer transfer) async {
    lastTransfer = transfer;
    transfers.add(transfer);
    return const Success(null);
  }
}

void main() {
  group('Account Use Cases', () {
    late FakeAccountRepository repo;

    setUp(() {
      repo = FakeAccountRepository();
    });

    const testAccount = Account(
      id: 'acc-1',
      name: 'Cash Wallet',
      type: AccountType.cash,
      currency: CurrencyCode.mmk,
      openingBalanceMinor: 100000,
      currentBalanceMinor: 100000,
      iconKey: 'wallet',
      colorValue: 0xFF5A8FE8,
      sortOrder: 0,
      isArchived: false,
      includeInTotal: true,
      createdAt: 1000,
      updatedAt: 1000,
    );

    test('WatchAccounts streams active accounts', () async {
      final useCase = WatchAccounts(repo);
      final stream = useCase(const WatchAccountsParams());

      final future = expectLater(
        stream.map((r) => r.valueOrNull?.length),
        emitsInOrder([1]),
      );

      await repo.saveAccount(account: testAccount, isNew: true);
      await future;
    });

    test('GetAccount returns account or not found', () async {
      final useCase = GetAccount(repo);
      await repo.saveAccount(account: testAccount, isNew: true);

      final found = await useCase('acc-1');
      expect(found.isSuccess, isTrue);
      expect(found.valueOrNull?.name, 'Cash Wallet');

      final notFound = await useCase('missing');
      expect(notFound.isErr, isTrue);
    });

    test(
      'SaveAccount validates required, length, and duplicate names',
      () async {
        final useCase = SaveAccount(repo);
        await repo.saveAccount(account: testAccount, isNew: true);

        // Empty name
        final emptyRes = await useCase(
          SaveAccountParams(account: testAccount.copyWith(name: '   ')),
        );
        expect(emptyRes.isErr, isTrue);
        expect(
          (emptyRes as Err).failure,
          isA<ValidationFailure>().having(
            (f) => f.fieldErrors['name'],
            'name',
            AccountValidators.nameRequired,
          ),
        );

        // Duplicate name
        final dupRes = await useCase(
          SaveAccountParams(
            account: testAccount.copyWith(id: 'acc-2', name: 'cash wallet'),
            isNew: true,
          ),
        );
        expect(dupRes.isErr, isTrue);
        expect(
          (dupRes as Err).failure,
          isA<ValidationFailure>().having(
            (f) => f.fieldErrors['name'],
            'name',
            AccountValidators.nameTaken,
          ),
        );

        // Valid update
        final successRes = await useCase(
          SaveAccountParams(
            account: testAccount.copyWith(name: 'Updated Wallet'),
            isNew: false,
          ),
        );
        expect(successRes.isSuccess, isTrue);
        expect(successRes.valueOrNull?.name, 'Updated Wallet');
      },
    );

    test('DeleteAccount and SetAccountArchived update account state', () async {
      final delete = DeleteAccount(repo);
      final archive = SetAccountArchived(repo);
      await repo.saveAccount(account: testAccount, isNew: true);

      await archive(
        const SetAccountArchivedParams(id: 'acc-1', isArchived: true),
      );
      expect(repo.accounts['acc-1']?.isArchived, isTrue);

      await delete('acc-1');
      expect(repo.accounts['acc-1']?.deletedAt, isNotNull);
    });

    test('ReorderAccounts assigns sequential sort orders', () async {
      final reorder = ReorderAccounts(repo);
      final acc2 = testAccount.copyWith(id: 'acc-2', name: 'Bank');
      await repo.saveAccount(account: testAccount, isNew: true);
      await repo.saveAccount(account: acc2, isNew: true);

      await reorder(['acc-2', 'acc-1']);
      expect(repo.accounts['acc-2']?.sortOrder, 0);
      expect(repo.accounts['acc-1']?.sortOrder, 1);
    });

    test(
      'TransferBetweenAccounts validates and commits fund transfer',
      () async {
        final transferUseCase = TransferBetweenAccounts(repo);

        // Invalid: same account
        final sameAccRes = await transferUseCase(
          AccountTransfer(
            fromAccountId: 'acc-1',
            toAccountId: 'acc-1',
            amount: const Money.minor(5000, CurrencyCode.mmk),
            date: LocalDate(2026, 10, 14),
          ),
        );
        expect(sameAccRes.isErr, isTrue);

        // Invalid: non-positive amount
        final zeroAmtRes = await transferUseCase(
          AccountTransfer(
            fromAccountId: 'acc-1',
            toAccountId: 'acc-2',
            amount: const Money.zero(CurrencyCode.mmk),
            date: LocalDate(2026, 10, 14),
          ),
        );
        expect(zeroAmtRes.isErr, isTrue);

        // Valid transfer
        final validRes = await transferUseCase(
          AccountTransfer(
            fromAccountId: 'acc-1',
            toAccountId: 'acc-2',
            amount: const Money.minor(5000, CurrencyCode.mmk),
            date: LocalDate(2026, 10, 14),
            note: 'Repay lunch',
          ),
        );
        expect(validRes.isSuccess, isTrue);
        expect(repo.lastTransfer?.amount.amountMinor, 5000);
        expect(repo.lastTransfer?.note, 'Repay lunch');
      },
    );
  });
}
