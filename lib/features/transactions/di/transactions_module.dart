import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:ledgerly/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:ledgerly/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:ledgerly/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/save_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/search_transactions.dart';
import 'package:ledgerly/features/transactions/domain/usecases/watch_transactions.dart';

/// Registers the transactions feature: datasource, repository and use cases.
///
/// Same lifetime rules as the categories module — lazy singletons for stateful
/// collaborators, factories for the stateless use cases
/// (`docs/Architecture.md` §10).
void registerTransactionsModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<TransactionLocalDataSource>(
      () => TransactionLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<TransactionRepository>(
      () => TransactionRepositoryImpl(getIt<TransactionLocalDataSource>()),
    );

  getIt
    ..registerFactory<WatchDayTransactions>(
      () => WatchDayTransactions(getIt<TransactionRepository>()),
    )
    ..registerFactory<WatchPeriodTransactions>(
      () => WatchPeriodTransactions(getIt<TransactionRepository>()),
    )
    ..registerFactory<WatchPeriodDailyTotals>(
      () => WatchPeriodDailyTotals(getIt<TransactionRepository>()),
    )
    ..registerFactory<WatchPeriodCategoryTotals>(
      () => WatchPeriodCategoryTotals(getIt<TransactionRepository>()),
    )
    ..registerFactory<WatchPeriodTotal>(
      () => WatchPeriodTotal(getIt<TransactionRepository>()),
    )
    ..registerFactory<WatchDayTotal>(
      () => WatchDayTotal(getIt<TransactionRepository>()),
    )
    ..registerFactory<GetTransaction>(
      () => GetTransaction(getIt<TransactionRepository>()),
    )
    ..registerFactory<SaveTransaction>(
      () => SaveTransaction(getIt<TransactionRepository>()),
    )
    ..registerFactory<DeleteTransaction>(
      () => DeleteTransaction(getIt<TransactionRepository>()),
    )
    ..registerFactory<RestoreTransaction>(
      () => RestoreTransaction(getIt<TransactionRepository>()),
    )
    ..registerFactory<SearchTransactions>(
      () => SearchTransactions(getIt<TransactionRepository>()),
    );
}
