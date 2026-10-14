import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';

/// Retrieves a recurring transaction by id.
class GetRecurringTransaction {
  const GetRecurringTransaction(this._repository);

  final RecurringRepository _repository;

  Future<RecurringTransaction?> call(String id) {
    return _repository.getById(id);
  }
}
