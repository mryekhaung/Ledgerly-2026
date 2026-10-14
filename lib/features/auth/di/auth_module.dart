import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:ledgerly/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ledgerly/features/auth/data/datasources/noop_auth_remote_datasource.dart';
import 'package:ledgerly/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';
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

/// Registers the auth feature's data and domain dependencies with [getIt].
///
/// Follows `docs/Architecture.md` §10:
/// - Lazy singletons for datasources and repositories.
/// - Factories for use cases.
/// - Remote datasource is swappable (e.g. Firebase vs Noop).
void registerAuthModule(GetIt getIt) {
  // Datasources
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(getIt<AppSettingsDao>()),
  );
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    NoopAuthRemoteDataSource.new,
  );

  // Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDataSource: getIt<AuthLocalDataSource>(),
      remoteDataSource: getIt<AuthRemoteDataSource>(),
    ),
  );

  // Use cases
  getIt.registerFactory<WatchAuthState>(
    () => WatchAuthState(getIt<AuthRepository>()),
  );
  getIt.registerFactory<GetCurrentUser>(
    () => GetCurrentUser(getIt<AuthRepository>()),
  );
  getIt.registerFactory<SignInAnonymously>(
    () => SignInAnonymously(getIt<AuthRepository>()),
  );
  getIt.registerFactory<SignInWithGoogle>(
    () => SignInWithGoogle(getIt<AuthRepository>()),
  );
  getIt.registerFactory<SignInWithApple>(
    () => SignInWithApple(getIt<AuthRepository>()),
  );
  getIt.registerFactory<SignInWithEmail>(
    () => SignInWithEmail(getIt<AuthRepository>()),
  );
  getIt.registerFactory<SignUpWithEmail>(
    () => SignUpWithEmail(getIt<AuthRepository>()),
  );
  getIt.registerFactory<LinkAccount>(
    () => LinkAccount(getIt<AuthRepository>()),
  );
  getIt.registerFactory<SignOut>(() => SignOut(getIt<AuthRepository>()));
  getIt.registerFactory<DeleteAccount>(
    () => DeleteAccount(getIt<AuthRepository>()),
  );
}
