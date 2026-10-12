import 'dart:async';

import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/domain/repositories/user_profile_repository.dart';

/// An in-memory [UserProfileRepository] for use-case tests.
///
/// Holds the profile in a broadcast controller so a test can assert that a save
/// is *observed* by a watcher — the contract that makes the Profile page and the
/// avatar on Settings both repaint without any manual sync.
///
/// Counts writes per method so a test can prove a rejected input never reached
/// storage, which is half of what the validation tests are checking.
class FakeUserProfileRepository implements UserProfileRepository {
  FakeUserProfileRepository({UserProfile? initial})
    : _current = initial ?? UserProfile.initial;

  UserProfile _current;

  /// When set, every call fails with this instead of succeeding.
  Failure? failure;

  /// How many times [save] was called.
  int saveCount = 0;

  /// How many times [saveAvatar] was called.
  int saveAvatarCount = 0;

  /// How many times [saveDisplayName] was called.
  int saveDisplayNameCount = 0;

  /// The last profile handed to [save], or null.
  UserProfile? lastSaved;

  /// The last avatar handed to [saveAvatar], or null.
  AvatarConfig? lastSavedAvatar;

  /// The last name handed to [saveDisplayName], or null.
  String? lastSavedName;

  final StreamController<UserProfile> _controller =
      StreamController<UserProfile>.broadcast();

  /// The profile currently held.
  UserProfile get current => _current;

  @override
  Future<Result<UserProfile>> load() async {
    if (failure case final failure?) return Err<UserProfile>(failure);
    return Success(_current);
  }

  @override
  Stream<Result<UserProfile>> watch() async* {
    if (failure case final failure?) {
      yield Err<UserProfile>(failure);
      return;
    }
    yield Success(_current);
    yield* _controller.stream.map(Success<UserProfile>.new);
  }

  @override
  Future<Result<void>> save(UserProfile profile) async {
    saveCount++;
    return _write(profile);
  }

  @override
  Future<Result<void>> saveAvatar(AvatarConfig avatar) async {
    saveAvatarCount++;
    lastSavedAvatar = avatar;
    return _write(_current.copyWith(avatar: avatar));
  }

  @override
  Future<Result<void>> saveDisplayName(String displayName) async {
    saveDisplayNameCount++;
    lastSavedName = displayName;
    return _write(_current.copyWith(displayName: displayName));
  }

  /// The shared write path, so the per-method counters above stay honest about
  /// which entry point the use case actually used.
  Result<void> _write(UserProfile profile) {
    if (failure case final failure?) return Err<void>(failure);
    lastSaved = profile;
    _current = profile;
    _controller.add(profile);
    return const Success<void>(null);
  }

  /// Releases the stream controller. Wired via `addTearDown` in watching tests.
  Future<void> dispose() => _controller.close();
}
