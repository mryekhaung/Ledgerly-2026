import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:ledgerly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ledgerly/features/settings/domain/repositories/settings_repository.dart';
import 'package:ledgerly/features/settings/domain/usecases/load_settings.dart';
import 'package:ledgerly/features/settings/domain/usecases/save_settings.dart';
import 'package:ledgerly/features/settings/domain/usecases/watch_settings.dart';

/// Registers the settings feature: datasource, repository and use cases.
///
/// **Lifetime rules** (`docs/Architecture.md` §10): the datasource and
/// repository are lazy singletons (they hold no per-screen state, and rebuilding
/// one per screen would reopen the watch stream); use cases are factories.
///
/// Requires [registerCoreModule] to have run — the datasource resolves
/// `getIt<AppDatabase>()`.
void registerSettingsModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSource(getIt<AppDatabase>().appSettingsDao),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(getIt<SettingsLocalDataSource>()),
    );

  getIt
    ..registerFactory<LoadSettings>(
      () => LoadSettings(getIt<SettingsRepository>()),
    )
    ..registerFactory<WatchSettings>(
      () => WatchSettings(getIt<SettingsRepository>()),
    )
    ..registerFactory<SaveSettings>(
      () => SaveSettings(getIt<SettingsRepository>()),
    );
}
