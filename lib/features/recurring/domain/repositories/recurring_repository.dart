import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_process_result.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';

/// Contract for persistent storage and scheduler processing of recurring transactions.
abstract class RecurringRepository {
  /// Watches all recurring transaction rules.
  Stream<List<RecurringTransaction>> watchAll({bool includeArchived = false});

  /// Retrieves all live active rules.
  Future<List<RecurringTransaction>> getAllActive();

  /// Retrieves a specific rule by [id].
  Future<RecurringTransaction?> getById(String id);

  /// Saves (creates or updates) a recurring rule.
  Future<void> save(RecurringTransaction item);

  /// Soft-deletes a recurring rule by [id].
  Future<void> delete(String id);

  /// Sets the paused/archived state of a rule.
  Future<void> setArchived(String id, bool isArchived);

  /// Skips the current `nextDueDate`, advancing to the following occurrence date.
  Future<void> skipNextDueDate(String id);

  /// Checks for due rules up to [targetDate] (defaults to today), creates transactions
  /// for `autoAdd == true`, identifies pending items for `autoAdd == false`, advances due dates,
  /// and dispatches notifications.
  Future<RecurringProcessResult> processDueTransactions({
    LocalDate? targetDate,
  });
}
