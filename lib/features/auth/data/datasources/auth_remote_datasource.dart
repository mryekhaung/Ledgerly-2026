import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';

/// Pluggable remote contract for external authentication providers (e.g. Firebase, Supabase).
///
/// Designed per `docs/Architecture.md` §4 and `docs/Agent.md` Rule 2.
abstract interface class AuthRemoteDataSource {
  /// Stream of remote authentication state changes.
  Stream<AuthUser?> watchAuthState();

  /// Gets the currently authenticated user from remote, or null.
  Future<AuthUser?> getCurrentUser();

  /// Creates or signs into an anonymous guest session.
  Future<AuthUser> signInAnonymously();

  /// Authenticates using Google credential.
  Future<AuthUser> signInWithGoogle();

  /// Authenticates using Sign in with Apple.
  Future<AuthUser> signInWithApple();

  /// Authenticates using email and password.
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registers a new remote account with email and password.
  Future<AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Links the current guest account to a permanent remote identity.
  Future<AuthUser> linkAccount({
    required AuthProviderType targetProvider,
    String? email,
    String? password,
  });

  /// Signs out of remote identity provider.
  Future<void> signOut();

  /// Permanently deletes the remote account and revokes tokens.
  Future<void> deleteAccount();
}
