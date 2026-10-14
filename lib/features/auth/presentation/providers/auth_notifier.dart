import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';

/// Presentation state for the user's authentication session.
class AuthState {
  const AuthState({this.user, this.isLoading = false, this.failure});

  final AuthUser? user;
  final bool isLoading;
  final Failure? failure;

  /// Whether a session exists (guest or permanent).
  bool get isAuthenticated => user != null;

  /// Whether running in anonymous/guest mode without linked credentials.
  bool get isGuest => user == null || user!.isAnonymous;

  /// Whether user has a permanent linked account (Google, Apple, or Email).
  bool get isPermanentAccount => user != null && !user!.isAnonymous;

  AuthState copyWith({
    AuthUser? user,
    bool clearUser = false,
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          isLoading == other.isLoading &&
          failure == other.failure;

  @override
  int get hashCode => Object.hash(user, isLoading, failure);
}

/// Riverpod 3 Notifier managing app-wide authentication state and user actions.
///
/// Kept alive app-wide (`docs/Architecture.md` §5): session lives for the app's lifetime.
class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<dynamic>? _subscription;

  @override
  AuthState build() {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
    });

    // Listen to reactive auth state stream from repository
    _subscription = ref
        .watch(watchAuthChangesProvider)
        .call(const NoParams())
        .listen((result) {
          if (result.isSuccess) {
            state = state.copyWith(
              user: result.valueOrNull,
              clearUser: result.valueOrNull == null,
              clearFailure: true,
            );
          }
        });

    // Trigger initial session check
    unawaited(_loadInitialSession());

    return const AuthState(isLoading: true);
  }

  Future<void> _loadInitialSession() async {
    final result = await ref
        .read(getCurrentUserProvider)
        .call(const NoParams());
    if (result.isSuccess) {
      state = state.copyWith(
        user: result.valueOrNull,
        clearUser: result.valueOrNull == null,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false, failure: result.failureOrNull);
    }
  }

  /// Continues as an anonymous guest.
  Future<bool> signInAnonymously() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref
        .read(signInAnonymouslyProvider)
        .call(const NoParams());
    return result.fold(
      onSuccess: (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
    );
  }

  /// Authenticates using Google Sign-In.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref
        .read(signInWithGoogleProvider)
        .call(const NoParams());
    return result.fold(
      onSuccess: (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
    );
  }

  /// Authenticates using Sign in with Apple.
  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref
        .read(signInWithAppleProvider)
        .call(const NoParams());
    return result.fold(
      onSuccess: (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
    );
  }

  /// Authenticates using email and password.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref.read(signInWithEmailProvider).call((
      email: email,
      password: password,
    ));
    return result.fold(
      onSuccess: (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
    );
  }

  /// Registers a new account with email and password.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref.read(signUpWithEmailProvider).call((
      email: email,
      password: password,
      displayName: displayName,
    ));
    return result.fold(
      onSuccess: (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
    );
  }

  /// Links existing guest session with Google, Apple, or Email.
  Future<bool> linkAccount({
    required AuthProviderType targetProvider,
    String? email,
    String? password,
  }) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref.read(linkAccountProvider).call((
      targetProvider: targetProvider,
      email: email,
      password: password,
    ));
    return result.fold(
      onSuccess: (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
    );
  }

  /// Signs out of the current session.
  Future<bool> signOut() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref.read(signOutProvider).call(const NoParams());
    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(clearUser: true, isLoading: false);
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
    );
  }

  /// Permanently deletes the account and revocations.
  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref.read(deleteAccountProvider).call(const NoParams());
    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(clearUser: true, isLoading: false);
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
    );
  }
}
