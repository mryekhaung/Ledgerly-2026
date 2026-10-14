import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/features/accounts/data/datasources/account_local_datasource.dart';
import 'package:ledgerly/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';
import 'package:ledgerly/features/accounts/domain/usecases/delete_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/get_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/reorder_accounts.dart';
import 'package:ledgerly/features/accounts/domain/usecases/save_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/set_account_archived.dart';
import 'package:ledgerly/features/accounts/domain/usecases/transfer_between_accounts.dart';
import 'package:ledgerly/features/accounts/domain/usecases/watch_accounts.dart';

/// Registers the accounts feature in GetIt: datasource, repository, and use cases.
void registerAccountsModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<AccountLocalDataSource>(
      () => AccountLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(getIt<AccountLocalDataSource>()),
    );

  // Factories for use cases
  getIt
    ..registerFactory<WatchAccounts>(
      () => WatchAccounts(getIt<AccountRepository>()),
    )
    ..registerFactory<GetAccount>(() => GetAccount(getIt<AccountRepository>()))
    ..registerFactory<SaveAccount>(
      () => SaveAccount(getIt<AccountRepository>()),
    )
    ..registerFactory<DeleteAccount>(
      () => DeleteAccount(getIt<AccountRepository>()),
    )
    ..registerFactory<SetAccountArchived>(
      () => SetAccountArchived(getIt<AccountRepository>()),
    )
    ..registerFactory<ReorderAccounts>(
      () => ReorderAccounts(getIt<AccountRepository>()),
    )
    ..registerFactory<TransferBetweenAccounts>(
      () => TransferBetweenAccounts(getIt<AccountRepository>()),
    );
}
