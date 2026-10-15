import 'package:flutter_riverpod/misc.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/auth/domain/usecases/delete_account.dart';
import 'package:ledgerly/features/auth/domain/usecases/get_current_user.dart';
import 'package:ledgerly/features/auth/domain/usecases/link_account.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_out.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:ledgerly/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';

import '../domain/fake_auth_repository.dart';

/// The override set every auth surface needs to render without DI.
///
/// The auth pages read their use cases straight out of `get_it`, so a widget
/// test (or a golden) that hosts one has to substitute all of them or the first
/// `read` throws. Keeping the list here means the three auth goldens and the
/// page suite cannot drift into slightly different wiring — which is exactly
/// how one of them ends up rendering an error banner and still "passing".
List<Override> authOverridesFor(FakeAuthRepository repository) => <Override>[
  watchAuthChangesProvider.overrideWithValue(WatchAuthState(repository)),
  getCurrentUserProvider.overrideWithValue(GetCurrentUser(repository)),
  signInAnonymouslyProvider.overrideWithValue(SignInAnonymously(repository)),
  signInWithGoogleProvider.overrideWithValue(SignInWithGoogle(repository)),
  signInWithAppleProvider.overrideWithValue(SignInWithApple(repository)),
  signInWithEmailProvider.overrideWithValue(SignInWithEmail(repository)),
  signUpWithEmailProvider.overrideWithValue(SignUpWithEmail(repository)),
  linkAccountProvider.overrideWithValue(LinkAccount(repository)),
  signOutProvider.overrideWithValue(SignOut(repository)),
  deleteAccountProvider.overrideWithValue(DeleteAccount(repository)),
  currentSettingsProvider.overrideWithValue(AppSettings.defaults),
  saveSettingsActionProvider.overrideWithValue(
    (params) async => Success(params.settings),
  ),
];
