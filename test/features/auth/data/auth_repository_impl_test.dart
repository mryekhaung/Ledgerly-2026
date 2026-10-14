import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:ledgerly/features/auth/data/datasources/noop_auth_remote_datasource.dart';
import 'package:ledgerly/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';

import '../../../core/database/db_harness.dart';

void main() {
  group('AuthRepositoryImpl', () {
    late AuthLocalDataSource localDataSource;
    late NoopAuthRemoteDataSource remoteDataSource;
    late AuthRepositoryImpl repository;

    setUp(() {
      final harness = useDbHarness();
      final dao = AppSettingsDao(harness.db, clock: harness.clock);
      localDataSource = AuthLocalDataSource(dao);
      remoteDataSource = NoopAuthRemoteDataSource();
      repository = AuthRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
      );
    });

    tearDown(() async {
      await remoteDataSource.dispose();
    });

    test('getCurrentUser returns null when fresh install', () async {
      final result = await repository.getCurrentUser();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test(
      'signInAnonymously persists guest session locally and remotely',
      () async {
        final result = await repository.signInAnonymously();
        expect(result.isSuccess, isTrue);
        final user = result.valueOrNull!;
        expect(user.isAnonymous, isTrue);
        expect(user.provider, AuthProviderType.anonymous);

        // Verify cached in local storage
        final cached = await localDataSource.read();
        expect(cached?.id, user.id);
        expect(cached?.isAnonymous, isTrue);
      },
    );

    test('signInWithGoogle persists google user', () async {
      final result = await repository.signInWithGoogle();
      expect(result.isSuccess, isTrue);
      final user = result.valueOrNull!;
      expect(user.isAnonymous, isFalse);
      expect(user.provider, AuthProviderType.google);

      final cached = await localDataSource.read();
      expect(cached?.id, user.id);
      expect(cached?.email, user.email);
    });

    test('signInWithApple persists apple user', () async {
      final result = await repository.signInWithApple();
      expect(result.isSuccess, isTrue);
      final user = result.valueOrNull!;
      expect(user.isAnonymous, isFalse);
      expect(user.provider, AuthProviderType.apple);
    });

    test('signInWithEmailAndPassword validates and persists user', () async {
      final result = await repository.signInWithEmailAndPassword(
        email: 'user@example.com',
        password: 'password123',
      );
      expect(result.isSuccess, isTrue);
      final user = result.valueOrNull!;
      expect(user.email, 'user@example.com');
      expect(user.provider, AuthProviderType.emailPassword);
    });

    test('linkAccount links guest session to permanent identity', () async {
      await repository.signInAnonymously();
      final linkResult = await repository.linkAccount(
        targetProvider: AuthProviderType.google,
        email: 'linked@example.com',
      );
      expect(linkResult.isSuccess, isTrue);
      final user = linkResult.valueOrNull!;
      expect(user.isAnonymous, isFalse);
      expect(user.provider, AuthProviderType.google);
      expect(user.email, 'linked@example.com');
    });

    test('signOut clears local storage and remote session', () async {
      await repository.signInWithGoogle();
      expect(await localDataSource.read(), isNotNull);

      final signOutResult = await repository.signOut();
      expect(signOutResult.isSuccess, isTrue);

      expect(await localDataSource.read(), isNull);
      expect(
        await repository.getCurrentUser().then((r) => r.valueOrNull),
        isNull,
      );
    });

    test(
      'deleteAccount removes local session and clears credentials',
      () async {
        await repository.signInWithGoogle();
        expect(await localDataSource.read(), isNotNull);

        final deleteResult = await repository.deleteAccount();
        expect(deleteResult.isSuccess, isTrue);

        expect(await localDataSource.read(), isNull);
      },
    );
  });
}
