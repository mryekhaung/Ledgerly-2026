import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

/// A template rule for scheduled recurring transactions.
///
/// Invariants:
/// - [amount] is strictly positive minor units.
/// - [startDate] is the first anchor date.
/// - [nextDueDate] is the date when the next occurrence is scheduled to happen.
/// - When [autoAdd] is true, the scheduler creates the actual transaction on app open.
/// - When [autoAdd] is false, the scheduler flags it as pending and alerts the user.
final class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.direction,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    required this.createdAt,
    required this.updatedAt,
    this.accountId,
    this.endDate,
    this.lastGeneratedDate,
    this.autoAdd = true,
    this.note,
    this.isArchived = false,
    this.deletedAt,
  });

  final String id;
  final String categoryId;
  final String? accountId;
  final Money amount;
  final TransactionDirection direction;
  final RecurringFrequency frequency;
  final LocalDate startDate;
  final LocalDate? endDate;
  final LocalDate nextDueDate;
  final LocalDate? lastGeneratedDate;
  final bool autoAdd;
  final String? note;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;

  int get amountMinor => amount.amountMinor;
  CurrencyCode get currency => amount.currency;

  bool get isActive => deletedAt == null && !isArchived;

  /// Returns true if this recurring rule has passed its end date.
  bool isExpired(LocalDate currentDate) {
    if (endDate == null) return false;
    return currentDate.isAfter(endDate!);
  }

  /// Returns true if this rule is due on or before [targetDate].
  bool isDue(LocalDate targetDate) {
    if (!isActive) return false;
    if (endDate != null && nextDueDate.isAfter(endDate!)) return false;
    return !nextDueDate.isAfter(targetDate);
  }

  RecurringTransaction copyWith({
    String? id,
    String? categoryId,
    String? accountId,
    bool clearAccountId = false,
    Money? amount,
    TransactionDirection? direction,
    RecurringFrequency? frequency,
    LocalDate? startDate,
    LocalDate? endDate,
    bool clearEndDate = false,
    LocalDate? nextDueDate,
    LocalDate? lastGeneratedDate,
    bool clearLastGeneratedDate = false,
    bool? autoAdd,
    String? note,
    bool clearNote = false,
    bool? isArchived,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastGeneratedDate: clearLastGeneratedDate
          ? null
          : (lastGeneratedDate ?? this.lastGeneratedDate),
      autoAdd: autoAdd ?? this.autoAdd,
      note: clearNote ? null : (note ?? this.note),
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          categoryId == other.categoryId &&
          accountId == other.accountId &&
          amount == other.amount &&
          direction == other.direction &&
          frequency == other.frequency &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          nextDueDate == other.nextDueDate &&
          lastGeneratedDate == other.lastGeneratedDate &&
          autoAdd == other.autoAdd &&
          note == other.note &&
          isArchived == other.isArchived &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    accountId,
    amount,
    direction,
    frequency,
    startDate,
    endDate,
    nextDueDate,
    lastGeneratedDate,
    autoAdd,
    note,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  );

  @override
  String toString() =>
      'RecurringTransaction($id, ${direction.name} $amount ${frequency.name}, next: $nextDueDate, auto: $autoAdd)';
}
