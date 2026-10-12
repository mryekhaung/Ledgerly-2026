import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/domain/repositories/user_profile_repository.dart';

/// Reads the local profile once.
class LoadUserProfile implements UseCase<UserProfile, NoParams> {
  const LoadUserProfile(this._repository);

  final UserProfileRepository _repository;

  @override
  Future<Result<UserProfile>> call(NoParams params) => _repository.load();
}
