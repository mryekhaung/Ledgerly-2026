/// Test fixtures for the database layer.
///
/// Lives in `lib/` rather than `test/` for the same reason
/// `openInMemoryDatabase()` does: unit tests, widget tests and the migration
/// harness all need the same rows, and three copies of "one expense, one income"
/// would drift apart. It imports nothing from `flutter_test`, so it adds no
/// test-only dependency to the app (`docs/Agent.md` §3.14).
///
/// Every helper **returns the new id** instead of leaving the caller to search
/// for the row it just created, which keeps a test's intent legible.
library;

import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/utils/local_date.dart';

/// Inserts one category with a unique name derived from [seed].
///
/// The name is suffixed so a test can insert several categories whose names sort
/// in a known order without the DAO's uniqueness check rejecting the second one.
Future<String> insertCategory(
  AppDatabase db, {
  required String seed,
  String kind = 'expense',
  int sortOrder = 0,
  bool isArchived = false,
  bool isDefault = false,
  int colorValue = 0xFFE8735A,
  int createdAt = 1000,
}) async {
  final id = 'cat-$seed';
  await db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          id: Value(id),
          name: 'Category $seed',
          iconKey: 'restaurant',
          colorValue: colorValue,
          kind: Value(kind),
          sortOrder: Value(sortOrder),
          isArchived: Value(isArchived),
          isDefault: Value(isDefault),
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
  return id;
}

/// Inserts one transaction. [date] is a [LocalDate] so the converter is exercised
/// on every insert rather than only in a dedicated test.
///
/// [amountMinor] is deliberately allowed to be any int — including negative —
/// so a test can prove the *schema* stores what it is given and that the
/// non-negative invariant is enforced by the DAO, not by SQLite.
Future<String> insertTransaction(
  AppDatabase db, {
  required String seed,
  required String categoryId,
  required int amountMinor,
  required LocalDate date,
  String direction = 'expense',
  String currency = 'mmk',
  String? accountId,
  String? note,
  int createdAt = 1000,
  int? deletedAt,
}) async {
  final id = 'txn-$seed';
  await db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          id: Value(id),
          categoryId: categoryId,
          accountId: Value(accountId),
          amountMinor: amountMinor,
          currency: currency,
          direction: direction,
          date: date,
          note: Value(note),
          createdAt: createdAt,
          updatedAt: createdAt,
          deletedAt: Value(deletedAt),
        ),
      );
  return id;
}

/// Inserts one account. `openingBalanceMinor` is signed — see
/// `docs/DataModel.md` §4.
Future<String> insertAccount(
  AppDatabase db, {
  required String seed,
  String type = 'cash',
  String currency = 'mmk',
  int openingBalanceMinor = 0,
  int sortOrder = 0,
  bool isArchived = false,
  bool includeInTotal = true,
  int createdAt = 1000,
}) async {
  final id = 'acct-$seed';
  await db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          id: Value(id),
          name: 'Account $seed',
          type: type,
          currency: currency,
          openingBalanceMinor: openingBalanceMinor,
          iconKey: 'wallet',
          colorValue: 0xFF5A8FE8,
          sortOrder: Value(sortOrder),
          isArchived: Value(isArchived),
          includeInTotal: Value(includeInTotal),
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
  return id;
}

/// A date in the middle of a month with 31 days, so `addDays` in a test cannot
/// accidentally roll into the next month.
LocalDate dayInOctober(int day) => LocalDate(2026, 10, day);
