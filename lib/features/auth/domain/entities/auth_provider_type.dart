/// Supported authentication providers for Ledgerly.
enum AuthProviderType {
  /// Local guest user session without remote credentials.
  anonymous,

  /// Google Sign-In.
  google,

  /// Sign in with Apple (Mandatory for iOS App Store compliance).
  apple,

  /// Email & Password credentials.
  emailPassword;

  /// Whether this is a permanent authenticated account (not guest).
  bool get isPermanent => this != AuthProviderType.anonymous;
}
