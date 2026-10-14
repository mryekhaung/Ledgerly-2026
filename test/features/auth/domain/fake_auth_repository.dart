import 'dart:async';

import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// In-memory fake for [AuthRepository].
///
/// Follows `docs/Conventions.md` §6: fakes over mocks so tests read as behavior.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  AuthUser? _currentUser;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  /// Forces all methods to return this failure instead of succeeding.
  Failure? forcedFailure;

  /// The current user for test assertions.
  AuthUser? get currentUser => _currentUser;
  set currentUser(AuthUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  /// Closes the stream controller.
  Future<void> dispose() => _controller.close();

  @override
  Stream<Result<AuthUser?>> watchAuthState() async* {
    if (forcedFailure case final failure?) {
      yield Err(failure);
      return;
    }
    yield Success(_currentUser);
    yield* _controller.stream.map((user) {
      if (forcedFailure case final failure?) {
        return Err(failure);
      }
      return Success(user);
    });
  }

  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    if (forcedFailure case final failure?) return Err(failure);
    return Success(_currentUser);
  }

  @override
  Future<Result<AuthUser>> signInAnonymously() async {
    if (forcedFailure case final failure?) return Err(failure);
    final user = AuthUser(
      id: 'guest-${DateTime.now().millisecondsSinceEpoch}',
      isAnonymous: true,
      provider: AuthProviderType.anonymous,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return Success(user);
  }

  @override
  Future<Result<AuthUser>> signInWithGoogle() async {
    if (forcedFailure case final failure?) return Err(failure);
    final user = AuthUser(
      id: 'google-user-123',
      email: 'google_user@example.com',
      displayName: 'Google User',
      photoUrl: 'https://example.com/photo.png',
      isAnonymous: false,
      provider: AuthProviderType.google,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return Success(user);
  }

  @override
  Future<Result<AuthUser>> signInWithApple() async {
    if (forcedFailure case final failure?) return Err(failure);
    final user = AuthUser(
      id: 'apple-user-456',
      email: 'apple_user@example.com',
      displayName: 'Apple User',
      isAnonymous: false,
      provider: AuthProviderType.apple,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return Success(user);
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (forcedFailure case final failure?) return Err(failure);
    if (password.length < 6) {
      return const Err(
        ValidationFailure(
          'Password too short',
          fieldErrors: {'password': 'authPasswordTooShort'},
        ),
      );
    }
    final user = AuthUser(
      id: 'email-user-${email.hashCode}',
      email: email,
      displayName: email.split('@').first,
      isAnonymous: false,
      provider: AuthProviderType.emailPassword,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return Success(user);
  }

  @override
  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (forcedFailure case final failure?) return Err(failure);
    if (!email.contains('@')) {
      return const Err(
        ValidationFailure(
          'Invalid email',
          fieldErrors: {'email': 'authInvalidEmail'},
        ),
      );
    }
    final user = AuthUser(
      id: 'new-email-user-${email.hashCode}',
      email: email,
      displayName: displayName ?? email.split('@').first,
      isAnonymous: false,
      provider: AuthProviderType.emailPassword,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return Success(user);
  }

  @override
  Future<Result<AuthUser>> linkAccount({
    required AuthProviderType targetProvider,
    String? email,
    String? password,
  }) async {
    if (forcedFailure case final failure?) return Err(failure);
    final current = _currentUser;
    if (current == null) {
      return const Err(AuthFailure('No active user to link'));
    }
    final linked = current.copyWith(
      isAnonymous: false,
      provider: targetProvider,
      email:
          email ??
          (targetProvider == AuthProviderType.google
              ? 'linked@gmail.com'
              : 'linked@icloud.com'),
      displayName: current.displayName ?? 'Linked User',
    );
    _currentUser = linked;
    _controller.add(linked);
    return Success(linked);
  }

  @override
  Future<Result<void>> signOut() async {
    if (forcedFailure case final failure?) return Err(failure);
    _currentUser = null;
    _controller.add(null);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    if (forcedFailure case final failure?) return Err(failure);
    _currentUser = null;
    _controller.add(null);
    return const Success(null);
  }
}
