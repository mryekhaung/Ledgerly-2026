import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';

/// Reads a single account by ID.
class GetAccount implements UseCase<Account, String> {
  const GetAccount(this._repository);

  final AccountRepository _repository;

  @override
  Future<Result<Account>> call(String id) {
    return _repository.getAccount(id);
  }
}
