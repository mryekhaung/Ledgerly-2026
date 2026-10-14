import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
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

import '../domain/fake_auth_repository.dart';

void main() {
  group('AuthNotifier', () {
    late FakeAuthRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          watchAuthChangesProvider.overrideWithValue(
            WatchAuthState(repository),
          ),
          getCurrentUserProvider.overrideWithValue(GetCurrentUser(repository)),
          signInAnonymouslyProvider.overrideWithValue(
            SignInAnonymously(repository),
          ),
          signInWithGoogleProvider.overrideWithValue(
            SignInWithGoogle(repository),
          ),
          signInWithAppleProvider.overrideWithValue(
            SignInWithApple(repository),
          ),
          signInWithEmailProvider.overrideWithValue(
            SignInWithEmail(repository),
          ),
          signUpWithEmailProvider.overrideWithValue(
            SignUpWithEmail(repository),
          ),
          linkAccountProvider.overrideWithValue(LinkAccount(repository)),
          signOutProvider.overrideWithValue(SignOut(repository)),
          deleteAccountProvider.overrideWithValue(DeleteAccount(repository)),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    test('initial state loads current user session', () async {
      final state = container.read(authNotifierProvider);
      expect(state.isLoading, isTrue);

      await Future<void>.delayed(Duration.zero);
      final updated = container.read(authNotifierProvider);
      expect(updated.isLoading, isFalse);
      expect(updated.user, isNull);
      expect(updated.isGuest, isTrue);
    });

    test('signInAnonymously signs in as guest', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signInAnonymously();

      expect(success, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.user, isNotNull);
      expect(state.user?.isAnonymous, isTrue);
      expect(state.isGuest, isTrue);
      expect(state.isPermanentAccount, isFalse);
    });

    test('signInWithGoogle signs in with Google identity', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signInWithGoogle();

      expect(success, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.user?.provider, AuthProviderType.google);
      expect(state.isGuest, isFalse);
      expect(state.isPermanentAccount, isTrue);
    });

    test('signInWithApple signs in with Apple identity', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signInWithApple();

      expect(success, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.user?.provider, AuthProviderType.apple);
      expect(state.isPermanentAccount, isTrue);
    });

    test('signInWithEmail validates and sets user', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signInWithEmail(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(success, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.user?.email, 'user@example.com');
      expect(state.user?.provider, AuthProviderType.emailPassword);
    });

    test('signUpWithEmail registers new account', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signUpWithEmail(
        email: 'newuser@example.com',
        password: 'password123',
        displayName: 'John Doe',
      );

      expect(success, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.user?.displayName, 'John Doe');
    });

    test('linkAccount links guest account to Google', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInAnonymously();
      expect(container.read(authNotifierProvider).isGuest, isTrue);

      final linkSuccess = await notifier.linkAccount(
        targetProvider: AuthProviderType.google,
        email: 'linked@gmail.com',
      );

      expect(linkSuccess, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.user?.email, 'linked@gmail.com');
      expect(state.isPermanentAccount, isTrue);
    });

    test('signOut clears user session', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();
      expect(container.read(authNotifierProvider).user, isNotNull);

      final success = await notifier.signOut();
      expect(success, isTrue);
      expect(container.read(authNotifierProvider).user, isNull);
    });

    test('deleteAccount clears session', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();
      expect(container.read(authNotifierProvider).user, isNotNull);

      final success = await notifier.deleteAccount();
      expect(success, isTrue);
      expect(container.read(authNotifierProvider).user, isNull);
    });

    test('failure updates state.failure', () async {
      repository.forcedFailure = const AuthFailure('Network error occurred');
      final notifier = container.read(authNotifierProvider.notifier);

      final success = await notifier.signInWithGoogle();
      expect(success, isFalse);
      final state = container.read(authNotifierProvider);
      expect(state.failure?.message, 'Network error occurred');
    });
  });
}
