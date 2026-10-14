import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';

final class SetAccountArchivedParams {
  const SetAccountArchivedParams({required this.id, required this.isArchived});

  final String id;
  final bool isArchived;
}

/// Archives or unarchives an account.
class SetAccountArchived implements UseCase<void, SetAccountArchivedParams> {
  const SetAccountArchived(this._repository);

  final AccountRepository _repository;

  @override
  Future<Result<void>> call(SetAccountArchivedParams params) {
    return _repository.setAccountArchived(params.id, params.isArchived);
  }
}
