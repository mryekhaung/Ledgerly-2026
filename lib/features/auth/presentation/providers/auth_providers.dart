import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';
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
import 'package:ledgerly/features/auth/presentation/providers/auth_notifier.dart';

/// Fallback repository used when GetIt is not configured (e.g. isolated widget tests).
class _FallbackAuthRepository implements AuthRepository {
  const _FallbackAuthRepository();

  @override
  Stream<Result<AuthUser?>> watchAuthState() =>
      Stream.value(const Success(null));

  @override
  Future<Result<AuthUser?>> getCurrentUser() async => const Success(null);

  @override
  Future<Result<AuthUser>> signInAnonymously() async =>
      const Err(AuthFailure('Auth unconfigured in test host'));

  @override
  Future<Result<AuthUser>> signInWithGoogle() async =>
      const Err(AuthFailure('Auth unconfigured in test host'));

  @override
  Future<Result<AuthUser>> signInWithApple() async =>
      const Err(AuthFailure('Auth unconfigured in test host'));

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => const Err(AuthFailure('Auth unconfigured in test host'));

  @override
  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async => const Err(AuthFailure('Auth unconfigured in test host'));

  @override
  Future<Result<AuthUser>> linkAccount({
    required AuthProviderType targetProvider,
    String? email,
    String? password,
  }) async => const Err(AuthFailure('Auth unconfigured in test host'));

  @override
  Future<Result<void>> signOut() async => const Success(null);

  @override
  Future<Result<void>> deleteAccount() async => const Success(null);
}

const _fallbackRepo = _FallbackAuthRepository();

/// Bridges get_it use cases to Riverpod providers (docs/Architecture.md §5, §10).
final watchAuthChangesProvider = Provider<WatchAuthState>(
  (_) => getIt.isRegistered<WatchAuthState>()
      ? getIt<WatchAuthState>()
      : const WatchAuthState(_fallbackRepo),
);

final getCurrentUserProvider = Provider<GetCurrentUser>(
  (_) => getIt.isRegistered<GetCurrentUser>()
      ? getIt<GetCurrentUser>()
      : const GetCurrentUser(_fallbackRepo),
);

final signInAnonymouslyProvider = Provider<SignInAnonymously>(
  (_) => getIt.isRegistered<SignInAnonymously>()
      ? getIt<SignInAnonymously>()
      : const SignInAnonymously(_fallbackRepo),
);

final signInWithGoogleProvider = Provider<SignInWithGoogle>(
  (_) => getIt.isRegistered<SignInWithGoogle>()
      ? getIt<SignInWithGoogle>()
      : const SignInWithGoogle(_fallbackRepo),
);

final signInWithAppleProvider = Provider<SignInWithApple>(
  (_) => getIt.isRegistered<SignInWithApple>()
      ? getIt<SignInWithApple>()
      : const SignInWithApple(_fallbackRepo),
);

final signInWithEmailProvider = Provider<SignInWithEmail>(
  (_) => getIt.isRegistered<SignInWithEmail>()
      ? getIt<SignInWithEmail>()
      : const SignInWithEmail(_fallbackRepo),
);

final signUpWithEmailProvider = Provider<SignUpWithEmail>(
  (_) => getIt.isRegistered<SignUpWithEmail>()
      ? getIt<SignUpWithEmail>()
      : const SignUpWithEmail(_fallbackRepo),
);

final linkAccountProvider = Provider<LinkAccount>(
  (_) => getIt.isRegistered<LinkAccount>()
      ? getIt<LinkAccount>()
      : const LinkAccount(_fallbackRepo),
);

final signOutProvider = Provider<SignOut>(
  (_) => getIt.isRegistered<SignOut>()
      ? getIt<SignOut>()
      : const SignOut(_fallbackRepo),
);

final deleteAccountProvider = Provider<DeleteAccount>(
  (_) => getIt.isRegistered<DeleteAccount>()
      ? getIt<DeleteAccount>()
      : const DeleteAccount(_fallbackRepo),
);

/// Raw stream of auth state changes as an AsyncValue.
final authStateStreamProvider = StreamProvider.autoDispose<AuthUser?>((ref) {
  final stream = ref.watch(watchAuthChangesProvider).call(const NoParams());
  return stream.map(
    (result) => result.fold(onSuccess: (user) => user, onErr: (_) => null),
  );
});

/// Riverpod 3 NotifierProvider managing the interactive auth session and actions.
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Current authenticated user (convenience selector).
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authNotifierProvider.select((s) => s.user));
});

/// Whether a user is currently authenticated (guest or permanent).
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider.select((s) => s.isAuthenticated));
});

/// Whether the current session is anonymous / guest mode.
final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider.select((s) => s.isGuest));
});
