import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';

/// Reads and writes the local user profile.
///
/// Phase 1 has a single local store. The interface exists now so presentation
/// never sees the datasource and a future cloud-synced profile is a new
/// implementation rather than a refactor of every call site
/// (`docs/Architecture.md` §4).
abstract interface class UserProfileRepository {
  /// The current profile. Never fails on a *decoding* problem — an unreadable
  /// value falls back to its default; a failure means storage is unavailable.
  Future<Result<UserProfile>> load();

  /// The profile, re-emitted whenever it changes.
  Stream<Result<UserProfile>> watch();

  /// Persists [profile] in full.
  Future<Result<void>> save(UserProfile profile);

  /// Persists just the avatar, leaving the name untouched.
  ///
  /// A dedicated method rather than `save(profile.copyWith(avatar: …))` so the
  /// avatar editor cannot accidentally write a stale display name it read
  /// before the user edited their name in another surface.
  Future<Result<void>> saveAvatar(AvatarConfig avatar);

  /// Persists just the display name, leaving the avatar untouched.
  Future<Result<void>> saveDisplayName(String displayName);
}
