import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:ledgerly/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:ledgerly/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:ledgerly/features/profile/domain/usecases/load_user_profile.dart';
import 'package:ledgerly/features/profile/domain/usecases/save_avatar.dart';
import 'package:ledgerly/features/profile/domain/usecases/save_display_name.dart';
import 'package:ledgerly/features/profile/domain/usecases/watch_user_profile.dart';

/// Registers the profile feature: datasource, repository and use cases.
///
/// **Lifetime rules** (`docs/Architecture.md` §10): the datasource and repository
/// are lazy singletons (they hold no per-screen state, and rebuilding one per
/// screen would reopen the watch stream); use cases are factories.
///
/// Requires `registerCoreModule` to have run — the datasource resolves
/// `getIt<AppDatabase>()`.
///
/// Registered alongside the settings module because both read the same
/// `app_settings` table through the same DAO; keeping them separate modules
/// means neither feature's wiring knows about the other.
void registerProfileModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<ProfileLocalDataSource>(
      () => ProfileLocalDataSource(getIt<AppDatabase>().appSettingsDao),
    )
    ..registerLazySingleton<UserProfileRepository>(
      () => UserProfileRepositoryImpl(getIt<ProfileLocalDataSource>()),
    );

  getIt
    ..registerFactory<LoadUserProfile>(
      () => LoadUserProfile(getIt<UserProfileRepository>()),
    )
    ..registerFactory<WatchUserProfile>(
      () => WatchUserProfile(getIt<UserProfileRepository>()),
    )
    ..registerFactory<SaveAvatar>(
      () => SaveAvatar(getIt<UserProfileRepository>()),
    )
    ..registerFactory<SaveDisplayName>(
      () => SaveDisplayName(getIt<UserProfileRepository>()),
    );
}
