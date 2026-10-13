import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/features/insights/data/datasources/insights_local_datasource.dart';
import 'package:ledgerly/features/insights/data/repositories/insights_repository_impl.dart';
import 'package:ledgerly/features/insights/domain/repositories/insights_repository.dart';
import 'package:ledgerly/features/insights/domain/usecases/watch_period_insights.dart';

/// Registers the insights feature: datasource, repository, and use cases.
void registerInsightsModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<InsightsLocalDataSource>(
      () => InsightsLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<InsightsRepository>(
      () => InsightsRepositoryImpl(getIt<InsightsLocalDataSource>()),
    )
    ..registerFactory<WatchPeriodInsights>(
      () => WatchPeriodInsights(getIt<InsightsRepository>()),
    );
}
