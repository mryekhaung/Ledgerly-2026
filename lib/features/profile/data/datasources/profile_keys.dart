/// The storage keys for the local user profile.
///
/// These live in the same `app_settings` key–value table as the preferences
/// (`docs/DataModel.md` §7), which is why they are namespaced with a
/// `profile_` prefix: the table is shared, so an unprefixed `name` would be
/// ambiguous against a future unrelated setting.
///
/// Grouped in one place so a read and a write can never disagree on a string
/// literal. Changing a key here is a **breaking** change to existing installs —
/// the old row would be orphaned and the value would revert to its default — so
/// keys are treated as append-only.
abstract final class ProfileKeys {
  const ProfileKeys._();

  /// The user's display name. Absent or empty means "not set yet".
  static const String displayName = 'profile_display_name';

  /// `AvatarConfig.encode()`, e.g. `2-0-1-3-0`.
  static const String avatar = 'profile_avatar';
}
