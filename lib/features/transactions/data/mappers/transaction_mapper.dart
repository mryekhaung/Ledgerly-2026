import 'package:drift/drift.dart' show Value;
import 'package:ledgerly/core/database/app_database.dart' as db;
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

/// Translates between the Drift transaction row and the pure-Dart [Transaction].
///
/// The only place the two representations meet for rows, so `domain/` never
/// imports `package:drift` (`docs/Agent.md` §3.1). Aggregate rows are built in
/// the datasource, where the `selectOnly` results are in scope.
///
/// **Name collision:** drift generates its row class as `Transaction`, the same
/// name as our entity, so the generated database is imported **prefixed** and
/// the row is referred to as `db.Transaction`.
///
/// Mappers are static and allocation-free so they can sit in a `Stream.map`
/// without a per-event object.
abstract final class TransactionMapper {
  const TransactionMapper._();

  /// Converts a Drift row into a domain entity.
  ///
  /// Throws [StateError] when the stored currency code or direction name is not
  /// one this build knows.
  ///
  /// Unlike [CategoryMapper], this one refuses to guess. A category with the
  /// wrong kind is a cosmetic mismatch; a transaction with the wrong *direction*
  /// flips the sign of the user's money in every total. The repository turns the
  /// throw into a `StorageFailure`, so the row surfaces as a problem instead of
  /// being plausibly wrong.
  static Transaction toEntity(db.Transaction row) {
    final currency = CurrencyCode.tryParse(row.currency);
    if (currency == null) {
      throw StateError('Unknown currency code "${row.currency}"');
    }
    final direction = TransactionDirection.tryParse(row.direction);
    if (direction == null) {
      throw StateError('Unknown transaction direction "${row.direction}"');
    }
    return Transaction(
      id: row.id,
      categoryId: row.categoryId,
      accountId: row.accountId,
      amount: Money.minor(row.amountMinor, currency),
      direction: direction,
      date: row.date,
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  /// Converts a list of rows, preserving order.
  static List<Transaction> toEntities(List<db.Transaction> rows) =>
      rows.map(toEntity).toList(growable: false);

  /// Builds the insert companion.
  ///
  /// The amount is written as the **unsigned magnitude** — [Money.amountMinor]
  /// directly, with the direction stored separately — so the sign cannot end up
  /// in two places (`docs/DataModel.md` §3).
  static db.TransactionsCompanion toInsertCompanion({
    required String id,
    required TransactionDraft draft,
    required int nowUtcMillis,
  }) => db.TransactionsCompanion.insert(
    id: Value(id),
    categoryId: draft.categoryId,
    amountMinor: draft.amount.abs().amountMinor,
    currency: draft.amount.currency.code.toLowerCase(),
    direction: draft.direction.storageValue,
    date: draft.date,
    note: Value(draft.note),
    createdAt: nowUtcMillis,
    updatedAt: nowUtcMillis,
  );

  /// Builds the update companion for an edit.
  ///
  /// Every field is materialised: the form submits a complete draft, so an
  /// absent field would silently retain a value the user had just cleared.
  static db.TransactionsCompanion toUpdateCompanion({
    required TransactionDraft draft,
    required int nowUtcMillis,
  }) => db.TransactionsCompanion(
    categoryId: Value(draft.categoryId),
    amountMinor: Value(draft.amount.abs().amountMinor),
    currency: Value(draft.amount.currency.code.toLowerCase()),
    direction: Value(draft.direction.storageValue),
    date: Value(draft.date),
    note: Value(draft.note),
    updatedAt: Value(nowUtcMillis),
  );
}
