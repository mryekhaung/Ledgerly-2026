import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// Parameters for [LinkAccount].
typedef LinkAccountParams = ({
  AuthProviderType targetProvider,
  String? email,
  String? password,
});

/// Links an existing guest/anonymous user account to a permanent provider.
///
/// Ensures all transactions and settings saved locally while in guest mode
/// are preserved under the new permanent user account identity.
class LinkAccount implements UseCase<AuthUser, LinkAccountParams> {
  const LinkAccount(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(LinkAccountParams params) =>
      _repository.linkAccount(
        targetProvider: params.targetProvider,
        email: params.email,
        password: params.password,
      );
}
