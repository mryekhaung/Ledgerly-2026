import 'dart:async';

import 'package:ledgerly/core/database/result_guard.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:ledgerly/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] combining [AuthLocalDataSource] and [AuthRemoteDataSource].
///
/// Designed per `docs/Architecture.md` §4:
/// - Source of truth for active session in memory & local SQLite storage.
/// - Wraps remote auth calls in [guardResult] and updates local session on successful auth.
/// - On sign-out or account delete, clears local storage.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
  }) : _local = localDataSource,
       _remote = remoteDataSource;

  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;

  Failure _mapAuthError(Object error, StackTrace stackTrace) {
    if (error is Failure) return error;
    final message = error.toString();
    if (message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('socket') ||
        message.toLowerCase().contains('timeout')) {
      return NetworkFailure(
        'Network error during authentication',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return AuthFailure(
      'Authentication failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Stream<Result<AuthUser?>> watchAuthState() =>
      guardResultStream(_local.watch());

  @override
  Future<Result<AuthUser?>> getCurrentUser() => guardResult(() async {
    final localUser = await _local.read();
    if (localUser != null) return localUser;
    final remoteUser = await _remote.getCurrentUser();
    if (remoteUser != null) {
      await _local.write(remoteUser);
    }
    return remoteUser;
  }, onError: _mapAuthError);

  @override
  Future<Result<AuthUser>> signInAnonymously() => guardResult(() async {
    final user = await _remote.signInAnonymously();
    await _local.write(user);
    return user;
  }, onError: _mapAuthError);

  @override
  Future<Result<AuthUser>> signInWithGoogle() => guardResult(() async {
    final user = await _remote.signInWithGoogle();
    await _local.write(user);
    return user;
  }, onError: _mapAuthError);

  @override
  Future<Result<AuthUser>> signInWithApple() => guardResult(() async {
    final user = await _remote.signInWithApple();
    await _local.write(user);
    return user;
  }, onError: _mapAuthError);

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => guardResult(() async {
    final user = await _remote.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _local.write(user);
    return user;
  }, onError: _mapAuthError);

  @override
  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) => guardResult(() async {
    final user = await _remote.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    await _local.write(user);
    return user;
  }, onError: _mapAuthError);

  @override
  Future<Result<AuthUser>> linkAccount({
    required AuthProviderType targetProvider,
    String? email,
    String? password,
  }) => guardResult(() async {
    final user = await _remote.linkAccount(
      targetProvider: targetProvider,
      email: email,
      password: password,
    );
    await _local.write(user);
    return user;
  }, onError: _mapAuthError);

  @override
  Future<Result<void>> signOut() => guardResult(() async {
    await _remote.signOut();
    await _local.clear();
  }, onError: _mapAuthError);

  @override
  Future<Result<void>> deleteAccount() => guardResult(() async {
    await _remote.deleteAccount();
    await _local.clear();
  }, onError: _mapAuthError);
}
