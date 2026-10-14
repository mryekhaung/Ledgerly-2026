import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/features/auth/data/datasources/auth_keys.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';

/// Local data source for reading and persisting the active authentication session.
///
/// Stores user identity in Drift's `app_settings` key-value table, ensuring
/// instantaneous session restoration upon cold app launch without waiting
/// for remote network calls (`docs/Architecture.md` §4, ADR #1).
class AuthLocalDataSource {
  const AuthLocalDataSource(this._dao);

  final AppSettingsDao _dao;

  /// Reads the current local session. Returns null if no user is signed in.
  Future<AuthUser?> read() async => _decode(await _dao.readAll());

  /// Emits the local session on any storage mutation.
  Stream<AuthUser?> watch() => _dao.watchAll().map(_decode);

  /// Saves the user session locally.
  Future<void> write(AuthUser user) => _dao.putAll(<String, String>{
    AuthKeys.userId: user.id,
    AuthKeys.email: ?user.email,
    AuthKeys.displayName: ?user.displayName,
    AuthKeys.photoUrl: ?user.photoUrl,
    AuthKeys.isAnonymous: user.isAnonymous.toString(),
    AuthKeys.provider: user.provider.name,
    if (user.createdAt case final created?)
      AuthKeys.createdAt: created.toIso8601String(),
  });

  /// Clears the local session on sign-out or account deletion.
  Future<void> clear() async {
    await _dao.remove(AuthKeys.userId);
    await _dao.remove(AuthKeys.email);
    await _dao.remove(AuthKeys.displayName);
    await _dao.remove(AuthKeys.photoUrl);
    await _dao.remove(AuthKeys.isAnonymous);
    await _dao.remove(AuthKeys.provider);
    await _dao.remove(AuthKeys.createdAt);
  }

  AuthUser? _decode(Map<String, String> raw) {
    final id = raw[AuthKeys.userId];
    if (id == null || id.isEmpty) return null;

    final isAnonymous = raw[AuthKeys.isAnonymous] == 'true';
    final providerStr = raw[AuthKeys.provider];
    final provider = AuthProviderType.values.firstWhere(
      (p) => p.name == providerStr,
      orElse: () => isAnonymous
          ? AuthProviderType.anonymous
          : AuthProviderType.emailPassword,
    );

    DateTime? createdAt;
    if (raw[AuthKeys.createdAt] case final dateStr?) {
      createdAt = DateTime.tryParse(dateStr);
    }

    return AuthUser(
      id: id,
      email: raw[AuthKeys.email],
      displayName: raw[AuthKeys.displayName],
      photoUrl: raw[AuthKeys.photoUrl],
      isAnonymous: isAnonymous,
      provider: provider,
      createdAt: createdAt,
    );
  }
}
