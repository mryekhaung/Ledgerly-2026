import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
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
import 'package:ledgerly/features/auth/presentation/pages/account_page.dart';
import 'package:ledgerly/features/auth/presentation/pages/sign_in_page.dart';
import 'package:ledgerly/features/auth/presentation/pages/welcome_page.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../domain/fake_auth_repository.dart';

void main() {
  group('Auth Presentation Pages', () {
    late FakeAuthRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeAuthRepository();
    });

    tearDown(() async {
      await fakeRepository.dispose();
    });

    List<Override> authOverrides() => [
      watchAuthChangesProvider.overrideWithValue(
        WatchAuthState(fakeRepository),
      ),
      getCurrentUserProvider.overrideWithValue(GetCurrentUser(fakeRepository)),
      signInAnonymouslyProvider.overrideWithValue(
        SignInAnonymously(fakeRepository),
      ),
      signInWithGoogleProvider.overrideWithValue(
        SignInWithGoogle(fakeRepository),
      ),
      signInWithAppleProvider.overrideWithValue(
        SignInWithApple(fakeRepository),
      ),
      signInWithEmailProvider.overrideWithValue(
        SignInWithEmail(fakeRepository),
      ),
      signUpWithEmailProvider.overrideWithValue(
        SignUpWithEmail(fakeRepository),
      ),
      linkAccountProvider.overrideWithValue(LinkAccount(fakeRepository)),
      signOutProvider.overrideWithValue(SignOut(fakeRepository)),
      deleteAccountProvider.overrideWithValue(DeleteAccount(fakeRepository)),
      currentSettingsProvider.overrideWithValue(AppSettings.defaults),
      saveSettingsActionProvider.overrideWithValue(
        (params) async => Success(params.settings),
      ),
    ];

    testWidgets(
      'WelcomePage renders branding, first-run question, and auth buttons',
      (tester) async {
        await pumpAppHost(
          tester,
          size: const Size(800, 1200),
          home: const WelcomePage(),
          overrides: authOverrides(),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome to Ledgerly'), findsOneWidget);
        expect(find.text('When does your month start?'), findsOneWidget);
        expect(find.text('Continue as Guest'), findsOneWidget);
        expect(find.text('Sign in with Google'), findsOneWidget);
        expect(find.text('Sign in with Apple'), findsOneWidget);
        expect(find.text('Sign in with Email'), findsOneWidget);
        expect(find.text('Skip for now'), findsOneWidget);

        // Verify day chips are rendered (e.g. Day 1 and Day 15)
        expect(find.text('1'), findsWidgets);
        expect(find.text('15'), findsOneWidget);

        // Tap day 15 chip to exercise selection
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        // Tap Continue as Guest
        await tester.tap(find.text('Continue as Guest'));
        await tester.pumpAndSettle();

        expect(fakeRepository.currentUser?.isAnonymous, isTrue);
      },
    );

    testWidgets(
      'SignInPage validates inputs and switches between Sign In and Sign Up modes',
      (tester) async {
        await pumpAppHost(
          tester,
          home: const SignInPage(),
          overrides: authOverrides(),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sign In'), findsWidgets);
        expect(find.text("Don't have an account? Sign up"), findsOneWidget);

        // Tap submit with empty fields to trigger validation
        await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
        await tester.pumpAndSettle();

        // Validation errors should be visible
        expect(find.text('Please check the highlighted fields.'), findsWidgets);

        // Switch to Sign Up mode
        await tester.tap(find.text("Don't have an account? Sign up"));
        await tester.pumpAndSettle();

        expect(find.text('Create Account'), findsWidgets);
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Already have an account? Sign in'), findsOneWidget);

        // Switch back to Sign In mode
        await tester.tap(find.text('Already have an account? Sign in'));
        await tester.pumpAndSettle();

        expect(find.text('Sign In'), findsWidgets);
        expect(find.text('Name'), findsNothing);
      },
    );

    testWidgets(
      'AccountPage renders guest mode, linking banner, and action dialogs',
      (tester) async {
        // Set initial user as guest
        fakeRepository.currentUser = const AuthUser(
          id: 'guest-1',
          isAnonymous: true,
          provider: AuthProviderType.anonymous,
        );

        await pumpAppHost(
          tester,
          home: const AccountPage(),
          overrides: authOverrides(),
        );
        await tester.pumpAndSettle();

        expect(find.text('Account'), findsOneWidget);
        expect(find.text('Guest Account'), findsOneWidget);
        expect(find.text('Save your data securely'), findsOneWidget);
        expect(find.text('Link Google Account'), findsOneWidget);
        expect(find.text('Link Apple ID'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);
        expect(find.text('Delete Account'), findsOneWidget);

        // Test Sign Out dialog cancellation
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Are you sure you want to sign out?'), findsNothing);

        // Test Delete Account dialog cancellation
        await tester.tap(find.text('Delete Account'));
        await tester.pumpAndSettle();

        expect(find.text('Delete permanently'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Delete permanently'), findsNothing);
      },
    );

    testWidgets('AccountPage renders synced user identity when signed in', (
      tester,
    ) async {
      fakeRepository.currentUser = const AuthUser(
        id: 'user-google-1',
        email: 'user@example.com',
        displayName: 'John Doe',
        isAnonymous: false,
        provider: AuthProviderType.google,
      );

      await pumpAppHost(
        tester,
        home: const AccountPage(),
        overrides: authOverrides(),
      );
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('Synced Account'), findsOneWidget);
      // Linking banner should NOT appear for already linked/permanent accounts
      expect(find.text('Save your data securely'), findsNothing);
    });
  });
}
