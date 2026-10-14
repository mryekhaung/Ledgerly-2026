import 'dart:async';

import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';

/// Local-first / dev implementation of [AuthRemoteDataSource].
///
/// Follows `docs/Architecture.md` §4 (ADR #1 & ADR #5):
/// - Operates fully offline without external Firebase credentials.
/// - Supports guest mode, local account linking, and simulated Apple/Google auth.
/// - Used for dev, prototype, and tests.
class NoopAuthRemoteDataSource implements AuthRemoteDataSource {
  NoopAuthRemoteDataSource({AuthUser? initialUser})
    : _currentUser = initialUser;

  AuthUser? _currentUser;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> watchAuthState() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AuthUser?> getCurrentUser() async => _currentUser;

  @override
  Future<AuthUser> signInAnonymously() async {
    final user = AuthUser(
      id: 'guest-${DateTime.now().millisecondsSinceEpoch}',
      isAnonymous: true,
      provider: AuthProviderType.anonymous,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = AuthUser(
      id: 'google-user-${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@gmail.com',
      displayName: 'Google User',
      photoUrl: 'https://lh3.googleusercontent.com/a/default-user',
      isAnonymous: false,
      provider: AuthProviderType.google,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithApple() async {
    final user = AuthUser(
      id: 'apple-user-${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@privaterelay.appleid.com',
      displayName: 'Apple User',
      isAnonymous: false,
      provider: AuthProviderType.apple,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (password.length < 6) {
      throw const ValidationFailure(
        'Password must be at least 6 characters.',
        fieldErrors: {'password': 'authPasswordTooShort'},
      );
    }
    final user = AuthUser(
      id: 'email-user-${email.hashCode.abs()}',
      email: email,
      displayName: email.split('@').first,
      isAnonymous: false,
      provider: AuthProviderType.emailPassword,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!email.contains('@')) {
      throw const ValidationFailure(
        'Invalid email format.',
        fieldErrors: {'email': 'authInvalidEmail'},
      );
    }
    if (password.length < 6) {
      throw const ValidationFailure(
        'Password must be at least 6 characters.',
        fieldErrors: {'password': 'authPasswordTooShort'},
      );
    }
    final user = AuthUser(
      id: 'email-user-${email.hashCode.abs()}',
      email: email,
      displayName: displayName ?? email.split('@').first,
      isAnonymous: false,
      provider: AuthProviderType.emailPassword,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> linkAccount({
    required AuthProviderType targetProvider,
    String? email,
    String? password,
  }) async {
    final current = _currentUser;
    if (current == null) {
      throw const AuthFailure('No active guest session to link.');
    }
    final linked = current.copyWith(
      isAnonymous: false,
      provider: targetProvider,
      email:
          email ??
          (targetProvider == AuthProviderType.google
              ? 'user@gmail.com'
              : 'user@privaterelay.appleid.com'),
      displayName:
          current.displayName ??
          (targetProvider == AuthProviderType.google
              ? 'Google User'
              : 'Apple User'),
    );
    _currentUser = linked;
    _controller.add(linked);
    return linked;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
    _controller.add(null);
  }

  /// Disposes the stream controller.
  Future<void> dispose() => _controller.close();
}
