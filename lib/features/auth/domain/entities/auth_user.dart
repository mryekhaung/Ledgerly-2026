import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';

/// Represents an authenticated or guest user session in Ledgerly.
///
/// Designed per `docs/Architecture.md` §1 & `docs/Agent.md` Rule 12:
/// - Guest mode (`isAnonymous = true`) is fully supported and offline-first.
/// - Remote identity fields (email, displayName, photoUrl) are populated when signed in.
final class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.provider = AuthProviderType.anonymous,
    this.createdAt,
  });

  /// The unique identifier (e.g. Firebase UID or client-generated guest ID).
  final String id;

  /// The user's primary email address, if linked.
  final String? email;

  /// The user's display name, if provided.
  final String? displayName;

  /// The user's profile photo URL, if available.
  final String? photoUrl;

  /// True when running as a local/anonymous guest without cloud credentials.
  final bool isAnonymous;

  /// The primary authentication provider used.
  final AuthProviderType provider;

  /// When the user account was first created.
  final DateTime? createdAt;

  /// Returns a copy of [AuthUser] with specified fields replaced.
  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    AuthProviderType? provider,
    DateTime? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          isAnonymous == other.isAnonymous &&
          provider == other.provider &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    displayName,
    photoUrl,
    isAnonymous,
    provider,
    createdAt,
  );

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, displayName: $displayName, isAnonymous: $isAnonymous, provider: $provider)';
}
