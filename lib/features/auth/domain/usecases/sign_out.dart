import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// Signs out the current user and clears active session.
class SignOut implements UseCase<void, NoParams> {
  const SignOut(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.signOut();
}
