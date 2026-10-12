import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';

/// The signed-in (or guest) user's profile.
///
/// Phase 1 has no account system, so this is always the local guest profile: a
/// display name and an avatar, both stored locally. Phase 2 adds an account and
/// this entity gains the remote identity fields then — the shape is deliberately
/// minimal now rather than pre-loading fields nothing can populate
/// (`docs/Agent.md` §8: no placeholder data).
///
/// Spec: `docs/Architecture.md` §2.
final class UserProfile {
  /// Creates a profile.
  const UserProfile({required this.displayName, required this.avatar});

  /// The profile a fresh install starts with.
  ///
  /// The name is **empty**, not a fake one: the UI shows a localized
  /// "Add your name" affordance instead, because inventing "Alex" would put a
  /// wrong name in front of every new user.
  static const UserProfile initial = UserProfile(
    displayName: '',
    avatar: AvatarConfig.initial,
  );

  /// The user's chosen name, or an empty string when they have not set one.
  ///
  /// Empty rather than null: "" and "unset" are the same state here, and one
  /// representation keeps every call site from handling both.
  final String displayName;

  /// The avatar composition.
  final AvatarConfig avatar;

  /// Whether the user has actually named themselves.
  bool get hasName => displayName.trim().isNotEmpty;

  /// A copy with the given fields replaced.
  UserProfile copyWith({String? displayName, AvatarConfig? avatar}) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        avatar: avatar ?? this.avatar,
      );

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.displayName == displayName &&
      other.avatar == avatar;

  @override
  int get hashCode => Object.hash(displayName, avatar);

  @override
  String toString() =>
      'UserProfile(displayName: $displayName, avatar: $avatar)';
}
