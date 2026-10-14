import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/savings_goals_dao.dart';
import 'package:ledgerly/features/goals/data/datasources/savings_goals_local_datasource.dart';
import 'package:ledgerly/features/goals/data/repositories/savings_goals_repository_impl.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';
import 'package:ledgerly/features/goals/domain/usecases/add_goal_contribution.dart';
import 'package:ledgerly/features/goals/domain/usecases/delete_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/get_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/save_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/set_goal_archived.dart';
import 'package:ledgerly/features/goals/domain/usecases/watch_savings_goals.dart';
import 'package:ledgerly/features/goals/domain/usecases/withdraw_from_goal.dart';

/// Registers the savings goals feature in GetIt: DAOs, datasource, repository, and use cases.
void registerGoalsModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<SavingsGoalsDao>(
      () => SavingsGoalsDao(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<SavingsGoalsLocalDataSource>(
      () => SavingsGoalsLocalDataSourceImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<SavingsGoalsRepository>(
      () => SavingsGoalsRepositoryImpl(getIt<SavingsGoalsLocalDataSource>()),
    );

  // Factories for use cases
  getIt
    ..registerFactory<WatchSavingsGoals>(
      () => WatchSavingsGoals(getIt<SavingsGoalsRepository>()),
    )
    ..registerFactory<GetSavingsGoal>(
      () => GetSavingsGoal(getIt<SavingsGoalsRepository>()),
    )
    ..registerFactory<SaveSavingsGoal>(
      () => SaveSavingsGoal(getIt<SavingsGoalsRepository>()),
    )
    ..registerFactory<AddGoalContribution>(
      () => AddGoalContribution(getIt<SavingsGoalsRepository>()),
    )
    ..registerFactory<WithdrawFromGoal>(
      () => WithdrawFromGoal(getIt<SavingsGoalsRepository>()),
    )
    ..registerFactory<SetGoalArchived>(
      () => SetGoalArchived(getIt<SavingsGoalsRepository>()),
    )
    ..registerFactory<DeleteSavingsGoal>(
      () => DeleteSavingsGoal(getIt<SavingsGoalsRepository>()),
    );
}
