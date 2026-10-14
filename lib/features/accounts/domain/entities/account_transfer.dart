import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';

/// Value object representing a fund transfer between two accounts.
///
/// Pure Dart: no Flutter, no Drift (docs/Agent.md §3.1).
final class AccountTransfer {
  const AccountTransfer({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.note,
  });

  /// The source account where funds are withdrawn.
  final String fromAccountId;

  /// The destination account where funds are deposited.
  final String toAccountId;

  /// The amount to transfer. Must be strictly positive.
  final Money amount;

  /// The business date of the transfer.
  final LocalDate date;

  /// Optional transfer note.
  final String? note;
}
