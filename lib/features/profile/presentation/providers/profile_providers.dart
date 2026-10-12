import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/domain/usecases/load_user_profile.dart';
import 'package:ledgerly/features/profile/domain/usecases/save_avatar.dart';
import 'package:ledgerly/features/profile/domain/usecases/save_display_name.dart';
import 'package:ledgerly/features/profile/domain/usecases/watch_user_profile.dart';

/// Thin bridge between get_it and Riverpod for the profile use cases.
///
/// `docs/Architecture.md` §5: presentation state lives in Riverpod; the use-case
/// instances come from the locator. Plain `Provider`s (not auto-disposed) — a use
/// case is stateless, so rebuilding one per screen allocates for nothing.
final loadUserProfileProvider = Provider<LoadUserProfile>(
  (_) => getIt<LoadUserProfile>(),
);

/// Bridge for [WatchUserProfile].
final watchUserProfileProvider = Provider<WatchUserProfile>(
  (_) => getIt<WatchUserProfile>(),
);

/// Bridge for [SaveAvatar].
final saveAvatarProvider = Provider<SaveAvatar>((_) => getIt<SaveAvatar>());

/// Bridge for [SaveDisplayName].
final saveDisplayNameProvider = Provider<SaveDisplayName>(
  (_) => getIt<SaveDisplayName>(),
);

/// The live profile, as an `AsyncValue`.
///
/// **`keepAlive`, not `autoDispose`.** The avatar and name are shown on more than
/// one surface (the Profile page, the Avatar Editor's preview) and a route
/// transition between them must not re-read the table and briefly flash the
/// default avatar.
///
/// A stream error collapses to the initial profile rather than surfacing a
/// failure: the app must still launch and be usable if the profile cannot be read,
/// and a missing name is a perfectly renderable state.
final userProfileProvider = StreamProvider<UserProfile>((ref) {
  final stream = ref.watch(watchUserProfileProvider).call(const NoParams());
  return stream.map(
    (result) => result.fold(
      onSuccess: (profile) => profile,
      onErr: (_) => UserProfile.initial,
    ),
  );
});

/// The current profile synchronously, defaulting while the first read lands.
///
/// Every reader that just needs *an* avatar uses this, so no call site renders a
/// loading state for a value that always exists in practice (SQLite read of two
/// rows, tens of milliseconds).
final currentUserProfileProvider = Provider<UserProfile>(
  (ref) => ref.watch(userProfileProvider).value ?? UserProfile.initial,
);

/// The avatar alone.
///
/// Separate from [currentUserProfileProvider] so the avatar editor's preview
/// repaints on an avatar change but not on a name change.
final currentAvatarProvider = Provider<AvatarConfig>(
  (ref) => ref.watch(currentUserProfileProvider).avatar,
  name: 'currentAvatar',
);

/// A source of randomness for the avatar editor's shuffle.
///
/// Overridden in tests so a generated avatar is reproducible. A provider rather
/// than a global `Random()` because "random" that cannot be seeded is untestable,
/// and the goldens depend on a fixed sequence.
final avatarRandomProvider = Provider<Random>((_) => Random());

/// Writes the avatar and returns the stored profile.
///
/// A function provider, not a state notifier: the stream is the single source of
/// truth, so a notifier holding its own copy would be a second one to keep in
/// sync. Callers `await ref.read(saveAvatarActionProvider)((avatar: config))` and
/// let [userProfileProvider] emit the result.
final saveAvatarActionProvider =
    Provider<Future<Result<UserProfile>> Function(SaveAvatarParams)>(
      (ref) => ref.read(saveAvatarProvider).call,
      name: 'saveAvatar',
    );

/// Renames the user and returns the stored profile.
final saveDisplayNameActionProvider =
    Provider<Future<Result<UserProfile>> Function(SaveDisplayNameParams)>(
      (ref) => ref.read(saveDisplayNameProvider).call,
      name: 'saveDisplayName',
    );
