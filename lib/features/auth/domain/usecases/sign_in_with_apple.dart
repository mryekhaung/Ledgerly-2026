import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// Signs in using Apple authentication (Mandatory for App Store compliance).
class SignInWithApple implements UseCase<AuthUser, NoParams> {
  const SignInWithApple(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(NoParams params) =>
      _repository.signInWithApple();
}
