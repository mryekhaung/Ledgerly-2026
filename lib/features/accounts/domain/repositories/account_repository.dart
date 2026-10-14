import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_transfer.dart';

/// Contract for accounts persistence and transfers.
///
/// Pure Dart: no Flutter, no Drift (docs/Agent.md §3.1, docs/Architecture.md §1).
abstract interface class AccountRepository {
  /// Live stream of active accounts (or all accounts if [includeArchived] is true).
  Stream<Result<List<Account>>> watchAccounts({bool includeArchived = false});

  /// Reads a single account by [id].
  Future<Result<Account>> getAccount(String id);

  /// Saves [account] (inserts if [isNew] is true, updates otherwise).
  Future<Result<Account>> saveAccount({
    required Account account,
    bool isNew = false,
  });

  /// Soft-deletes [id].
  Future<Result<void>> deleteAccount(String id);

  /// Archives or unarchives [id].
  Future<Result<void>> setAccountArchived(String id, bool isArchived);

  /// Reorders accounts by setting their `sortOrder` to match [orderedIds].
  Future<Result<void>> reorderAccounts(List<String> orderedIds);

  /// Whether an active account named [name] already exists.
  Future<Result<bool>> nameExists(String name, {String? excludingId});

  /// Calculates the current balance of [accountId] in minor units.
  Future<Result<int>> calculateAccountBalance(String accountId);

  /// Performs an atomic funds transfer between two accounts.
  Future<Result<void>> transferFunds(AccountTransfer transfer);
}
