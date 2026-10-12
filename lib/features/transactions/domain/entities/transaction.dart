import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

/// One money movement. The centre of the app.
///
/// The domain's own type — deliberately **not** the Drift row class, so
/// `domain/` stays pure Dart (`docs/Agent.md` §3.1, `docs/Architecture.md` §1).
/// Note this file does not import `package:drift`; the `Transaction` row class
/// drift generates has the same name, and the mapper is the only place the two
/// meet.
///
/// Immutable value type: every "change" is a `copyWith` returning a new
/// instance.
///
/// Spec: `docs/DataModel.md` §3.
final class Transaction {
  /// Creates a transaction.
  ///
  /// [amount] carries the magnitude **and** the currency; [direction] carries
  /// the sign. The amount is never negative — see [TransactionDirection].
  const Transaction({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.direction,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.accountId,
    this.note,
    this.deletedAt,
  });

  /// Client-generated UUIDv4 — created offline, before any server exists
  /// (`docs/Architecture.md` ADR #3).
  final String id;

  /// Owning category.
  final String categoryId;

  /// Owning account, once accounts ship in v0.3. Null for a v1 row.
  final String? accountId;

  /// The magnitude and its currency.
  ///
  /// Always **positive** — direction lives in [direction]. Exposed as [Money]
  /// rather than a bare `int` so the currency cannot be lost when the value
  /// leaves this object, and so no arithmetic can accidentally mix currencies.
  final Money amount;

  /// Which way the money moved.
  final TransactionDirection direction;

  /// The business day the user picked — a *day*, not an instant
  /// (`docs/DataModel.md` §3).
  final LocalDate date;

  /// Free text.
  final String? note;

  /// UTC epoch milliseconds, set on insert.
  final int createdAt;

  /// UTC epoch milliseconds, bumped on every write so a future outbox can diff
  /// (`docs/DataModel.md` §1).
  final int updatedAt;

  /// UTC epoch milliseconds when soft-deleted, or null while live.
  final int? deletedAt;

  /// The amount in minor units. Convenience for callers that only need the
  /// integer (sort keys, SQL-bound params).
  int get amountMinor => amount.amountMinor;

  /// The currency this transaction is denominated in.
  CurrencyCode get currency => amount.currency;

  /// The signed magnitude: negative for [TransactionDirection.expense].
  ///
  /// **Display and net-total use only.** Never persist this — the stored amount
  /// is unsigned and the sign is derived from [direction]
  /// (`docs/DataModel.md` §3).
  int get signedMinor => direction == TransactionDirection.expense
      ? -amount.amountMinor
      : amount.amountMinor;

  /// True while this row is live (not soft-deleted).
  bool get isActive => deletedAt == null;

  /// True when this is money out.
  bool get isExpense => direction == TransactionDirection.expense;

  /// True when this is money in.
  bool get isIncome => direction == TransactionDirection.income;

  /// Returns a copy with the given fields replaced.
  ///
  /// [accountId], [note] and [deletedAt] are nullable, so a plain
  /// `x ?? this.x` could never clear them. Each gets an explicit `clear*` flag —
  /// the undo affordance needs `clearDeletedAt`, and clearing a note is a
  /// legitimate edit.
  Transaction copyWith({
    String? categoryId,
    String? accountId,
    Money? amount,
    TransactionDirection? direction,
    LocalDate? date,
    String? note,
    int? updatedAt,
    int? deletedAt,
    bool clearAccountId = false,
    bool clearNote = false,
    bool clearDeletedAt = false,
  }) => Transaction(
    id: id,
    categoryId: categoryId ?? this.categoryId,
    accountId: clearAccountId ? null : (accountId ?? this.accountId),
    amount: amount ?? this.amount,
    direction: direction ?? this.direction,
    date: date ?? this.date,
    note: clearNote ? null : (note ?? this.note),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
  );

  /// The transaction with its [direction] flipped.
  ///
  /// Flips the *direction*, not the sign of the amount — the amount stays a
  /// positive magnitude, which is the invariant the whole schema rests on.
  Transaction toggled() => copyWith(direction: direction.opposite);

  /// Value equality across every persisted field.
  @override
  bool operator ==(Object other) =>
      other is Transaction &&
      other.id == id &&
      other.categoryId == categoryId &&
      other.accountId == accountId &&
      other.amount == amount &&
      other.direction == direction &&
      other.date == date &&
      other.note == note &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    accountId,
    amount,
    direction,
    date,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  );

  @override
  String toString() =>
      'Transaction($id, ${direction.name} ${amount.toString()} on $date)';
}

/// The fields a caller may set when creating or editing a transaction.
///
/// A record rather than a class because it is a pure parameter bag with no
/// behaviour — and a record cannot be accidentally given a `copyWith` that
/// reimplements the entity's (`docs/Conventions.md` §1).
typedef TransactionDraft = ({
  String categoryId,
  Money amount,
  TransactionDirection direction,
  LocalDate date,
  String? note,
});
