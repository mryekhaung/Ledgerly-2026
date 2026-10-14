import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// Parameters for [SignInWithEmail].
typedef SignInWithEmailParams = ({String email, String password});

/// Authenticates a user with email and password.
class SignInWithEmail implements UseCase<AuthUser, SignInWithEmailParams> {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(SignInWithEmailParams params) =>
      _repository.signInWithEmailAndPassword(
        email: params.email,
        password: params.password,
      );
}
