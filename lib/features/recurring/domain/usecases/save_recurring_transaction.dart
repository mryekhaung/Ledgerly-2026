import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';

/// Saves (creates or updates) a recurring transaction rule.
class SaveRecurringTransaction {
  const SaveRecurringTransaction(this._repository);

  final RecurringRepository _repository;

  Future<void> call(RecurringTransaction item) {
    return _repository.save(item);
  }
}
