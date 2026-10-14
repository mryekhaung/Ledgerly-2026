import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';

/// The outcome of running the recurring transaction scheduler.
final class RecurringProcessResult {
  const RecurringProcessResult({
    required this.generatedTransactions,
    required this.pendingRecurring,
  });

  /// Automatically created real transactions.
  final List<Transaction> generatedTransactions;

  /// Recurring transactions due that require user confirmation (`autoAdd == false`).
  final List<RecurringTransaction> pendingRecurring;

  int get generatedCount => generatedTransactions.length;
  int get pendingCount => pendingRecurring.length;

  bool get hasAnyAction => generatedCount > 0 || pendingCount > 0;

  static const empty = RecurringProcessResult(
    generatedTransactions: <Transaction>[],
    pendingRecurring: <RecurringTransaction>[],
  );
}
