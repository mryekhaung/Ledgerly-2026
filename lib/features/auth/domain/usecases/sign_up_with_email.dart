import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// Parameters for [SignUpWithEmail].
typedef SignUpWithEmailParams = ({
  String email,
  String password,
  String? displayName,
});

/// Registers a new user account with email and password.
class SignUpWithEmail implements UseCase<AuthUser, SignUpWithEmailParams> {
  const SignUpWithEmail(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(SignUpWithEmailParams params) =>
      _repository.signUpWithEmailAndPassword(
        email: params.email,
        password: params.password,
        displayName: params.displayName,
      );
}
