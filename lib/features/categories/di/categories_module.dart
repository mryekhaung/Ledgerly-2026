import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/features/categories/data/datasources/category_local_datasource.dart';
import 'package:ledgerly/features/categories/data/repositories/category_repository_impl.dart';
import 'package:ledgerly/features/categories/domain/repositories/category_repository.dart';
import 'package:ledgerly/features/categories/domain/usecases/delete_category.dart';
import 'package:ledgerly/features/categories/domain/usecases/get_category.dart';
import 'package:ledgerly/features/categories/domain/usecases/save_category.dart';
import 'package:ledgerly/features/categories/domain/usecases/watch_categories.dart';

/// Registers the categories feature: datasource, repository and use cases.
///
/// **Lifetime rules** (`docs/Architecture.md` §10):
/// - the datasource and repository are **lazy singletons** — a repository holds
///   no per-screen state, and rebuilding one per screen would reopen streams;
/// - use cases are **factories** — they are stateless and cheap, and a factory
///   keeps a long-lived reference from outliving the screen that grabbed it.
///
/// Requires `registerCoreModule` to have run: every `getIt<AppDatabase>()` call
/// below resolves the singleton registered there.
void registerCategoriesModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<CategoryLocalDataSource>(
      () => CategoryLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(getIt<CategoryLocalDataSource>()),
    );

  // Factories, not singletons — see the lifetime rules above.
  getIt
    ..registerFactory<WatchCategories>(
      () => WatchCategories(getIt<CategoryRepository>()),
    )
    ..registerFactory<WatchPickableCategories>(
      () => WatchPickableCategories(getIt<CategoryRepository>()),
    )
    ..registerFactory<GetCategory>(
      () => GetCategory(getIt<CategoryRepository>()),
    )
    ..registerFactory<SaveCategory>(
      () => SaveCategory(getIt<CategoryRepository>()),
    )
    ..registerFactory<DeleteCategory>(
      () => DeleteCategory(getIt<CategoryRepository>()),
    )
    ..registerFactory<RestoreCategory>(
      () => RestoreCategory(getIt<CategoryRepository>()),
    )
    ..registerFactory<SetCategoryArchived>(
      () => SetCategoryArchived(getIt<CategoryRepository>()),
    )
    ..registerFactory<ReorderCategories>(
      () => ReorderCategories(getIt<CategoryRepository>()),
    );
}
