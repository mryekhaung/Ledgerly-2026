import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/budgets_dao.dart';
import 'package:ledgerly/core/database/daos/categories_dao.dart';
import 'package:ledgerly/core/database/daos/transactions_dao.dart';
import 'package:ledgerly/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:ledgerly/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';
import 'package:ledgerly/features/budgets/domain/usecases/delete_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/get_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/get_budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/usecases/save_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/set_budget_archived.dart';
import 'package:ledgerly/features/budgets/domain/usecases/watch_budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/usecases/watch_budgets.dart';

/// Registers the budgets feature in GetIt: DAOs, datasource, repository, and use cases.
void registerBudgetsModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<BudgetsDao>(() => BudgetsDao(getIt<AppDatabase>()))
    ..registerLazySingleton<BudgetLocalDataSource>(
      () => BudgetLocalDataSourceImpl(
        budgetsDao: getIt<BudgetsDao>(),
        transactionsDao: getIt<TransactionsDao>(),
        categoriesDao: getIt<CategoriesDao>(),
      ),
    )
    ..registerLazySingleton<BudgetRepository>(
      () => BudgetRepositoryImpl(getIt<BudgetLocalDataSource>()),
    );

  // Factories for use cases
  getIt
    ..registerFactory<WatchBudgets>(
      () => WatchBudgets(getIt<BudgetRepository>()),
    )
    ..registerFactory<GetBudget>(() => GetBudget(getIt<BudgetRepository>()))
    ..registerFactory<SaveBudget>(() => SaveBudget(getIt<BudgetRepository>()))
    ..registerFactory<DeleteBudget>(
      () => DeleteBudget(getIt<BudgetRepository>()),
    )
    ..registerFactory<SetBudgetArchived>(
      () => SetBudgetArchived(getIt<BudgetRepository>()),
    )
    ..registerFactory<WatchBudgetProgress>(
      () => WatchBudgetProgress(getIt<BudgetRepository>()),
    )
    ..registerFactory<GetBudgetProgress>(
      () => GetBudgetProgress(getIt<BudgetRepository>()),
    );
}
