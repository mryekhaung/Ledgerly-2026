import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/domain/repositories/user_profile_repository.dart';

/// Watches the local profile.
///
/// The profile is edited from the Profile page and the Avatar Editor, so the
/// stream is what keeps both surfaces — and the avatar in any future app bar —
/// in agreement without either holding a copy.
class WatchUserProfile implements StreamUseCase<UserProfile, NoParams> {
  const WatchUserProfile(this._repository);

  final UserProfileRepository _repository;

  @override
  Stream<Result<UserProfile>> call(NoParams params) => _repository.watch();
}
