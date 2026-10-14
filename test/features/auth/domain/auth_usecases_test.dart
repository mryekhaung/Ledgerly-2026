import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/auth/domain/usecases/delete_account.dart';
import 'package:ledgerly/features/auth/domain/usecases/link_account.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_out.dart';
import 'package:ledgerly/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:ledgerly/features/auth/domain/usecases/watch_auth_state.dart';

import 'fake_auth_repository.dart';

void main() {
  group('Auth Domain Entities', () {
    test('AuthUser equality and copyWith', () {
      const user1 = AuthUser(
        id: 'u-1',
        email: 'test@example.com',
        displayName: 'Test',
        isAnonymous: false,
        provider: AuthProviderType.google,
      );
      const user2 = AuthUser(
        id: 'u-1',
        email: 'test@example.com',
        displayName: 'Test',
        isAnonymous: false,
        provider: AuthProviderType.google,
      );
      final user3 = user1.copyWith(displayName: 'Updated');

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
      expect(user1, isNot(equals(user3)));
      expect(user3.displayName, 'Updated');
    });

    test('AuthProviderType isPermanent', () {
      expect(AuthProviderType.anonymous.isPermanent, isFalse);
      expect(AuthProviderType.google.isPermanent, isTrue);
      expect(AuthProviderType.apple.isPermanent, isTrue);
      expect(AuthProviderType.emailPassword.isPermanent, isTrue);
    });
  });

  group('Auth Domain Use Cases', () {
    late FakeAuthRepository repository;

    setUp(() {
      repository = FakeAuthRepository();
    });

    tearDown(() async {
      await repository.dispose();
    });

    test('SignInAnonymously returns guest user', () async {
      final useCase = SignInAnonymously(repository);
      final result = await useCase(const NoParams());

      expect(result.isSuccess, isTrue);
      final user = result.valueOrNull!;
      expect(user.isAnonymous, isTrue);
      expect(user.provider, AuthProviderType.anonymous);
    });

    test('SignInWithGoogle returns authenticated google user', () async {
      final useCase = SignInWithGoogle(repository);
      final result = await useCase(const NoParams());

      expect(result.isSuccess, isTrue);
      final user = result.valueOrNull!;
      expect(user.isAnonymous, isFalse);
      expect(user.provider, AuthProviderType.google);
      expect(user.email, contains('@'));
    });

    test('SignInWithApple returns authenticated apple user', () async {
      final useCase = SignInWithApple(repository);
      final result = await useCase(const NoParams());

      expect(result.isSuccess, isTrue);
      final user = result.valueOrNull!;
      expect(user.isAnonymous, isFalse);
      expect(user.provider, AuthProviderType.apple);
    });

    test('SignInWithEmail authenticates valid credentials', () async {
      final useCase = SignInWithEmail(repository);
      final result = await useCase((
        email: 'user@example.com',
        password: 'securePassword123',
      ));

      expect(result.isSuccess, isTrue);
      final user = result.valueOrNull!;
      expect(user.email, 'user@example.com');
      expect(user.provider, AuthProviderType.emailPassword);
    });

    test('SignUpWithEmail registers user', () async {
      final useCase = SignUpWithEmail(repository);
      final result = await useCase((
        email: 'newuser@example.com',
        password: 'password123',
        displayName: 'New Member',
      ));

      expect(result.isSuccess, isTrue);
      final user = result.valueOrNull!;
      expect(user.displayName, 'New Member');
      expect(user.email, 'newuser@example.com');
    });

    test('LinkAccount converts guest account to permanent provider', () async {
      await SignInAnonymously(repository)(const NoParams());
      expect(repository.currentUser?.isAnonymous, isTrue);

      final linkUseCase = LinkAccount(repository);
      final result = await linkUseCase((
        targetProvider: AuthProviderType.google,
        email: 'linked@gmail.com',
        password: null,
      ));

      expect(result.isSuccess, isTrue);
      final user = result.valueOrNull!;
      expect(user.isAnonymous, isFalse);
      expect(user.provider, AuthProviderType.google);
      expect(user.email, 'linked@gmail.com');
    });

    test('SignOut clears current user', () async {
      await SignInWithGoogle(repository)(const NoParams());
      expect(repository.currentUser, isNotNull);

      final result = await SignOut(repository)(const NoParams());
      expect(result.isSuccess, isTrue);
      expect(repository.currentUser, isNull);
    });

    test('DeleteAccount clears user and data', () async {
      await SignInWithGoogle(repository)(const NoParams());
      expect(repository.currentUser, isNotNull);

      final result = await DeleteAccount(repository)(const NoParams());
      expect(result.isSuccess, isTrue);
      expect(repository.currentUser, isNull);
    });

    test('WatchAuthState emits on state changes', () async {
      final watchUseCase = WatchAuthState(repository);
      final emissions = <AuthUser?>[];

      final sub = watchUseCase(const NoParams()).listen((result) {
        if (result.isSuccess) {
          emissions.add(result.valueOrNull);
        }
      });
      await Future<void>.delayed(Duration.zero);

      await SignInAnonymously(repository)(const NoParams());
      await SignInWithGoogle(repository)(const NoParams());
      await SignOut(repository)(const NoParams());

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(3));
      expect(emissions.any((u) => u?.isAnonymous == true), isTrue);
      expect(
        emissions.any((u) => u?.provider == AuthProviderType.google),
        isTrue,
      );
      expect(emissions.last, isNull);
    });

    test('handles failure gracefully', () async {
      repository.forcedFailure = const AuthFailure('Failed to authenticate');

      final result = await SignInAnonymously(repository)(const NoParams());
      expect(result.isErr, isTrue);
      expect(result.failureOrNull?.message, 'Failed to authenticate');
    });
  });
}
