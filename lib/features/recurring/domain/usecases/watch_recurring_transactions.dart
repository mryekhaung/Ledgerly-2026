import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';

/// Watches all recurring transaction rules.
class WatchRecurringTransactions {
  const WatchRecurringTransactions(this._repository);

  final RecurringRepository _repository;

  Stream<List<RecurringTransaction>> call({bool includeArchived = false}) {
    return _repository.watchAll(includeArchived: includeArchived);
  }
}
