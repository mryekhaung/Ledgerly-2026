import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/result/result_guard.dart';
import 'package:ledgerly/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/domain/repositories/user_profile_repository.dart';

/// Drift-backed [UserProfileRepository].
///
/// Every call is funnelled through `guardResult` / `guardResultStream` — the
/// single seam where a `data/` exception becomes a `Failure`
/// (`docs/Architecture.md` §8). No `try`/`catch` appears above this line.
class UserProfileRepositoryImpl implements UserProfileRepository {
  const UserProfileRepositoryImpl(this._local);

  final ProfileLocalDataSource _local;

  @override
  Future<Result<UserProfile>> load() => guardResult(_local.read);

  @override
  Stream<Result<UserProfile>> watch() => guardResultStream(_local.watch());

  @override
  Future<Result<void>> save(UserProfile profile) =>
      guardResult(() => _local.write(profile));

  @override
  Future<Result<void>> saveAvatar(AvatarConfig avatar) =>
      guardResult(() => _local.writeAvatar(avatar));

  @override
  Future<Result<void>> saveDisplayName(String displayName) =>
      guardResult(() => _local.writeDisplayName(displayName));
}
