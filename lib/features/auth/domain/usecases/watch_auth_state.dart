import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// Listens to user authentication state changes.
class WatchAuthState implements StreamUseCase<AuthUser?, NoParams> {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  @override
  Stream<Result<AuthUser?>> call(NoParams params) =>
      _repository.watchAuthState();
}
