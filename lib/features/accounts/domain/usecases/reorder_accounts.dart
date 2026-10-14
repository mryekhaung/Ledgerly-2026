import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';

/// Reorders accounts to match the specified ID list.
class ReorderAccounts implements UseCase<void, List<String>> {
  const ReorderAccounts(this._repository);

  final AccountRepository _repository;

  @override
  Future<Result<void>> call(List<String> orderedIds) {
    return _repository.reorderAccounts(orderedIds);
  }
}
