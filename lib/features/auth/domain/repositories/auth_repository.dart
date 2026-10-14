import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';

/// Contract for authentication operations in Ledgerly.
///
/// Designed per `docs/Architecture.md` §1, §4 & `docs/Agent.md` Rule 2:
/// - Pure Dart interface without Firebase/Supabase dependencies.
/// - Implementations live in `data/` and can be swapped via DI.
/// - Returns `Result<T>` for all operations without throwing exceptions.
abstract interface class AuthRepository {
  /// Emits the current [AuthUser] whenever auth state transitions (sign in, sign out, link).
  Stream<Result<AuthUser?>> watchAuthState();

  /// Gets the currently authenticated user, or null if no session exists.
  Future<Result<AuthUser?>> getCurrentUser();

  /// Initiates or continues an anonymous guest session.
  Future<Result<AuthUser>> signInAnonymously();

  /// Authenticates using Google Sign-In.
  Future<Result<AuthUser>> signInWithGoogle();

  /// Authenticates using Sign in with Apple.
  Future<Result<AuthUser>> signInWithApple();

  /// Authenticates using email and password.
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registers a new user account with email and password.
  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Links an existing guest/anonymous account to a permanent provider
  /// (e.g. Google, Apple, or Email/Password), preserving existing local data.
  Future<Result<AuthUser>> linkAccount({
    required AuthProviderType targetProvider,
    String? email,
    String? password,
  });

  /// Signs out of the current session.
  Future<Result<void>> signOut();

  /// Permanently deletes the current user account and revocations.
  /// Mandatory for Apple App Store and Google Play Store compliance.
  Future<Result<void>> deleteAccount();
}
