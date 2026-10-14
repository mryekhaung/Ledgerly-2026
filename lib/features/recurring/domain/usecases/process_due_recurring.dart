import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_process_result.dart';
import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';

/// The recurring transaction scheduler.
///
/// Runs on app open / resume or manual trigger. Identifies all rules due on or before `targetDate`
/// (defaults to today), automatically posts transactions for rules with `autoAdd == true`,
/// flags pending rules with `autoAdd == false`, and schedules or delivers alerts.
class ProcessDueRecurring {
  const ProcessDueRecurring(this._repository);

  final RecurringRepository _repository;

  Future<RecurringProcessResult> call({LocalDate? targetDate}) {
    return _repository.processDueTransactions(targetDate: targetDate);
  }
}
