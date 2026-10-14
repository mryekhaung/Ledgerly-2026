import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';

/// Soft-deletes a recurring transaction rule.
class DeleteRecurringTransaction {
  const DeleteRecurringTransaction(this._repository);

  final RecurringRepository _repository;

  Future<void> call(String id) {
    return _repository.delete(id);
  }
}
