import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// Permanently deletes the user account.
///
/// Mandatory for store compliance (Apple App Store Guideline 5.1.1(v) & Google Play policy).
class DeleteAccount implements UseCase<void, NoParams> {
  const DeleteAccount(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.deleteAccount();
}
