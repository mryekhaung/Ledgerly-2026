/// Storage keys for persisting auth session state in AppSettingsDao.
abstract final class AuthKeys {
  const AuthKeys._();

  static const String userId = 'auth_user_id';
  static const String email = 'auth_email';
  static const String displayName = 'auth_display_name';
  static const String photoUrl = 'auth_photo_url';
  static const String isAnonymous = 'auth_is_anonymous';
  static const String provider = 'auth_provider';
  static const String createdAt = 'auth_created_at';
}
