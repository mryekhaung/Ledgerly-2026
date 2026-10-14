import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';

/// Skips the next occurrence of a recurring transaction rule without creating a transaction.
class SkipRecurringOccurrence {
  const SkipRecurringOccurrence(this._repository);

  final RecurringRepository _repository;

  Future<void> call(String id) {
    return _repository.skipNextDueDate(id);
  }
}
