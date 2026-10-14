import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// Signs in using Google authentication.
class SignInWithGoogle implements UseCase<AuthUser, NoParams> {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(NoParams params) =>
      _repository.signInWithGoogle();
}
