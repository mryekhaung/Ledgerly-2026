import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/domain/repositories/user_profile_repository.dart';

/// Parameters for [SaveAvatar].
typedef SaveAvatarParams = ({AvatarConfig avatar});

/// Persists a new avatar.
///
/// Validates the config before writing: the renderer clamps out-of-range indices
/// defensively, but storing something the editor could not have produced would
/// make the stored value and the UI disagree about what was chosen. A rejected
/// save leaves the previous avatar in place, which is the correct outcome for a
/// malformed request.
///
/// Returns the **whole profile**, not the avatar: the stream is the source of
/// truth for the name as well, and a caller that only got the avatar back would
/// be tempted to keep its own copy of the rest.
class SaveAvatar implements UseCase<UserProfile, SaveAvatarParams> {
  const SaveAvatar(this._repository);

  final UserProfileRepository _repository;

  @override
  Future<Result<UserProfile>> call(SaveAvatarParams params) async {
    if (!params.avatar.isValid) {
      return const Err<UserProfile>(
        ValidationFailure(
          'Avatar configuration references an unknown option',
          fieldErrors: <String, String>{},
          cause: null,
        ),
      );
    }

    // The write is checked explicitly rather than via `flatMap`, which is
    // synchronous and cannot await the re-read. Returning the stored write's
    // failure (not the read's) keeps the reported reason about the save.
    final written = await _repository.saveAvatar(params.avatar);
    if (written case Err<void>(:final failure)) {
      return Err<UserProfile>(failure);
    }

    return _repository.load();
  }
}
