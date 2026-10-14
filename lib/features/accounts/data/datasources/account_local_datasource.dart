import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart' hide Account;
import 'package:ledgerly/core/database/daos/accounts_dao.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/daos/transactions_dao.dart';
import 'package:ledgerly/core/database/uuid.dart';
import 'package:ledgerly/features/accounts/data/mappers/account_mapper.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_transfer.dart';

/// Database operations for Accounts and Transfers.
class AccountLocalDataSource {
  AccountLocalDataSource(
    this._db, {
    AccountsDao? accountsDao,
    TransactionsDao? transactionsDao,
    this.clock = const Clock(),
  }) : _accountsDao = accountsDao ?? _db.accountsDao,
       _transactionsDao = transactionsDao ?? _db.transactionsDao;

  final AppDatabase _db;
  final AccountsDao _accountsDao;
  final TransactionsDao _transactionsDao;
  final Clock clock;

  /// Calculates the current balance of [accountId] given its [openingBalanceMinor].
  Future<int> calculateBalance(
    String accountId,
    int openingBalanceMinor,
  ) async {
    final txs =
        await (_db.select(_db.transactions)..where(
              (t) => t.accountId.equals(accountId) & t.deletedAt.isNull(),
            ))
            .get();

    var netMovement = 0;
    for (final t in txs) {
      if (t.direction == 'income') {
        netMovement += t.amountMinor;
      } else if (t.direction == 'expense') {
        netMovement -= t.amountMinor;
      } else if (t.direction == 'transfer') {
        final note = t.note ?? '';
        if (note.startsWith('[transfer:in:')) {
          netMovement += t.amountMinor;
        } else {
          netMovement -= t.amountMinor;
        }
      }
    }
    return openingBalanceMinor + netMovement;
  }

  /// Watches all accounts, computing live current balance for each.
  Stream<List<Account>> watchAccounts({bool includeArchived = false}) {
    return _accountsDao.watchAll().asyncMap((accountRows) async {
      final filtered = includeArchived
          ? accountRows
          : accountRows.where((a) => !a.isArchived).toList();

      final result = <Account>[];
      for (final row in filtered) {
        final balance = await calculateBalance(row.id, row.openingBalanceMinor);
        result.add(AccountMapper.toEntity(row, currentBalanceMinor: balance));
      }
      return result;
    });
  }

  /// Reads a single account by ID with its live balance.
  Future<Account?> getAccount(String id) async {
    final row = await _accountsDao.findById(id);
    if (row == null) return null;
    final balance = await calculateBalance(row.id, row.openingBalanceMinor);
    return AccountMapper.toEntity(row, currentBalanceMinor: balance);
  }

  /// Saves an account (insert or update).
  Future<Account> saveAccount({
    required Account account,
    bool isNew = false,
  }) async {
    final now = clock.nowUtcMillis();
    if (isNew) {
      final id = account.id.isEmpty ? generateUuid() : account.id;
      final inserted = account.copyWith(id: id, createdAt: now, updatedAt: now);
      await _db
          .into(_db.accounts)
          .insert(AccountMapper.toInsertCompanion(inserted, nowUtcMillis: now));
      final balance = await calculateBalance(id, inserted.openingBalanceMinor);
      return inserted.copyWith(currentBalanceMinor: balance);
    } else {
      final updated = account.copyWith(updatedAt: now);
      await (_db.update(_db.accounts)..where((t) => t.id.equals(account.id)))
          .write(AccountMapper.toUpdateCompanion(updated, nowUtcMillis: now));
      final balance = await calculateBalance(
        account.id,
        updated.openingBalanceMinor,
      );
      return updated.copyWith(currentBalanceMinor: balance);
    }
  }

  /// Soft-deletes an account.
  Future<void> deleteAccount(String id) async {
    await _accountsDao.softDelete(id);
  }

  /// Archives or unarchives an account.
  Future<void> setAccountArchived(String id, bool isArchived) async {
    await _accountsDao.setArchived(id, isArchived: isArchived);
  }

  /// Reorders accounts by setting sequential sort order.
  Future<void> reorderAccounts(List<String> orderedIds) async {
    await _accountsDao.reorder(orderedIds);
  }

  /// Checks if an active account with [name] exists.
  Future<bool> nameExists(String name, {String? excludingId}) async {
    final lowered = name.trim().toLowerCase();
    final all = await (_db.select(
      _db.accounts,
    )..where((t) => t.deletedAt.isNull())).get();

    return all.any(
      (a) => a.id != excludingId && a.name.trim().toLowerCase() == lowered,
    );
  }

  /// Executes an atomic funds transfer between two accounts.
  Future<void> transferFunds(AccountTransfer transfer) async {
    await _db.transaction(() async {
      // Find or create a transfer category
      var transferCategory =
          await (_db.select(_db.categories)
                ..where((c) => c.kind.equals('transfer') & c.deletedAt.isNull())
                ..limit(1))
              .getSingleOrNull();

      if (transferCategory == null) {
        // Fallback to any non-deleted category or insert a Transfer category
        final anyCat =
            await (_db.select(_db.categories)
                  ..where((c) => c.deletedAt.isNull())
                  ..limit(1))
                .getSingleOrNull();

        if (anyCat != null) {
          transferCategory = anyCat;
        } else {
          final catId = generateUuid();
          final now = clock.nowUtcMillis();
          await _db
              .into(_db.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: Value(catId),
                  name: 'Transfer',
                  iconKey: 'sync_alt',
                  colorValue: 0xFF5A8FE8,
                  kind: const Value('transfer'),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
          transferCategory = await (_db.select(
            _db.categories,
          )..where((c) => c.id.equals(catId))).getSingle();
        }
      }

      final transferCatId = transferCategory.id;
      final now = clock.nowUtcMillis();

      // 1. Outgoing transaction
      final outNote =
          '[transfer:out:${transfer.toAccountId}] ${transfer.note ?? ""}'
              .trim();
      await _transactionsDao.insert(
        categoryId: transferCatId,
        amountMinor: transfer.amount.amountMinor,
        currency: transfer.amount.currency.name,
        direction: 'transfer',
        date: transfer.date,
        accountId: transfer.fromAccountId,
        note: outNote,
        nowUtcMillis: now,
      );

      // 2. Incoming transaction
      final inNote =
          '[transfer:in:${transfer.fromAccountId}] ${transfer.note ?? ""}'
              .trim();
      await _transactionsDao.insert(
        categoryId: transferCatId,
        amountMinor: transfer.amount.amountMinor,
        currency: transfer.amount.currency.name,
        direction: 'transfer',
        date: transfer.date,
        accountId: transfer.toAccountId,
        note: inNote,
        nowUtcMillis: now + 1,
      );
    });
  }
}
