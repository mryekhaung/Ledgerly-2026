import 'package:ledgerly/core/database/result_guard.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/accounts/data/datasources/account_local_datasource.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_transfer.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';

/// Concrete implementation of [AccountRepository].
class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._dataSource);

  final AccountLocalDataSource _dataSource;

  @override
  Stream<Result<List<Account>>> watchAccounts({bool includeArchived = false}) {
    return guardResultStream(
      _dataSource.watchAccounts(includeArchived: includeArchived),
    );
  }

  @override
  Future<Result<Account>> getAccount(String id) {
    return guardResult(
      () async {
        final acc = await _dataSource.getAccount(id);
        if (acc == null) {
          throw const NotFoundFailure('Account not found');
        }
        return acc;
      },
      onError: (err, st) {
        if (err is Failure) return err;
        return FailureMapper.fromStorage(err, st);
      },
    );
  }

  @override
  Future<Result<Account>> saveAccount({
    required Account account,
    bool isNew = false,
  }) {
    return guardResult(
      () => _dataSource.saveAccount(account: account, isNew: isNew),
    );
  }

  @override
  Future<Result<void>> deleteAccount(String id) {
    return guardResult(() => _dataSource.deleteAccount(id));
  }

  @override
  Future<Result<void>> setAccountArchived(String id, bool isArchived) {
    return guardResult(() => _dataSource.setAccountArchived(id, isArchived));
  }

  @override
  Future<Result<void>> reorderAccounts(List<String> orderedIds) {
    return guardResult(() => _dataSource.reorderAccounts(orderedIds));
  }

  @override
  Future<Result<bool>> nameExists(String name, {String? excludingId}) {
    return guardResult(
      () => _dataSource.nameExists(name, excludingId: excludingId),
    );
  }

  @override
  Future<Result<int>> calculateAccountBalance(String accountId) {
    return guardResult(() async {
      final acc = await _dataSource.getAccount(accountId);
      if (acc == null) throw const NotFoundFailure('Account not found');
      return acc.currentBalanceMinor;
    });
  }

  @override
  Future<Result<void>> transferFunds(AccountTransfer transfer) {
    return guardResult(() => _dataSource.transferFunds(transfer));
  }
}
