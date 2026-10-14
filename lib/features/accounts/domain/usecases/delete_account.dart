import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';

/// Soft-deletes an account.
class DeleteAccount implements UseCase<void, String> {
  const DeleteAccount(this._repository);

  final AccountRepository _repository;

  @override
  Future<Result<void>> call(String id) {
    return _repository.deleteAccount(id);
  }
}
