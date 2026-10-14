import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// Signs in as an anonymous guest.
class SignInAnonymously implements UseCase<AuthUser, NoParams> {
  const SignInAnonymously(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(NoParams params) =>
      _repository.signInAnonymously();
}
