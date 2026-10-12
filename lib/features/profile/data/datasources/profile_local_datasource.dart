import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/features/profile/data/datasources/profile_keys.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';

/// Reads and writes the local profile in the `app_settings` key–value table.
///
/// Owns **every** Drift type and every storage key, so nothing above it — the
/// repository, use cases, providers — knows how the profile is spelled on disk
/// (`docs/Architecture.md` §4).
///
/// Reuses [AppSettingsDao] rather than introducing a table: the profile is two
/// scalar values, which is exactly what a key–value store is for, and a
/// dedicated table would mean a migration for no schema benefit.
class ProfileLocalDataSource {
  ProfileLocalDataSource(this._dao);

  final AppSettingsDao _dao;

  /// The current profile, decoded.
  Future<UserProfile> read() async => _decode(await _dao.readAll());

  /// Emits the profile on every write.
  ///
  /// Wraps the settings stream, so a name edit in one surface repaints the avatar
  /// in another without either holding a copy.
  Stream<UserProfile> watch() => _dao.watchAll().map(_decode);

  /// Writes the whole profile.
  Future<void> write(UserProfile profile) => _dao.putAll(<String, String>{
    ProfileKeys.displayName: profile.displayName,
    ProfileKeys.avatar: profile.avatar.encode(),
  });

  /// Writes just the avatar, leaving the name untouched.
  Future<void> writeAvatar(AvatarConfig avatar) =>
      _dao.put(key: ProfileKeys.avatar, value: avatar.encode());

  /// Writes just the display name, leaving the avatar untouched.
  Future<void> writeDisplayName(String displayName) =>
      _dao.put(key: ProfileKeys.displayName, value: displayName);

  /// Decodes the two raw values into a [UserProfile].
  ///
  /// **Unreadable value → default, not a failure.** A name or avatar written by
  /// a newer build (say a sixth avatar slot) must not brick launch: the worst
  /// case is the profile falls back to its default and the user re-picks. That is
  /// far better than an error screen the user cannot dismiss, which is what
  /// throwing here would produce — the same rule the settings datasource follows.
  UserProfile _decode(Map<String, String> raw) {
    final name = raw[ProfileKeys.displayName] ?? '';
    final avatar = AvatarConfig.tryParse(raw[ProfileKeys.avatar] ?? '');

    // An out-of-range index (a build with fewer options) is treated the same way
    // as a malformed string: fall back to the initial avatar rather than handing
    // the renderer something it would have to clamp.
    final resolvedAvatar = (avatar != null && avatar.isValid)
        ? avatar
        : UserProfile.initial.avatar;

    return UserProfile(displayName: name, avatar: resolvedAvatar);
  }
}
