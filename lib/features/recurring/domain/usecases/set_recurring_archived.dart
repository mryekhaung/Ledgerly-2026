import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';

/// Sets the paused/archived status of a recurring transaction rule.
class SetRecurringArchived {
  const SetRecurringArchived(this._repository);

  final RecurringRepository _repository;

  Future<void> call({required String id, required bool isArchived}) {
    return _repository.setArchived(id, isArchived);
  }
}
