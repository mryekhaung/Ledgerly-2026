import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/recurring_dao.dart';
import 'package:ledgerly/features/recurring/data/datasources/recurring_local_datasource.dart';
import 'package:ledgerly/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:ledgerly/features/recurring/data/services/in_app_recurring_notification_service.dart';
import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:ledgerly/features/recurring/domain/services/recurring_notification_service.dart';
import 'package:ledgerly/features/recurring/domain/usecases/delete_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/get_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/process_due_recurring.dart';
import 'package:ledgerly/features/recurring/domain/usecases/save_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/set_recurring_archived.dart';
import 'package:ledgerly/features/recurring/domain/usecases/skip_recurring_occurrence.dart';
import 'package:ledgerly/features/recurring/domain/usecases/watch_recurring_transactions.dart';

/// Registers the recurring transactions feature in GetIt: DAOs, datasource, repository, and use cases.
void registerRecurringModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<RecurringDao>(
      () => RecurringDao(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<RecurringNotificationService>(
      InAppRecurringNotificationService.new,
    )
    ..registerLazySingleton<RecurringLocalDataSource>(
      () => RecurringLocalDataSourceImpl(
        getIt<AppDatabase>(),
        notificationService: getIt<RecurringNotificationService>(),
      ),
    )
    ..registerLazySingleton<RecurringRepository>(
      () => RecurringRepositoryImpl(getIt<RecurringLocalDataSource>()),
    );

  // Factories for use cases
  getIt
    ..registerFactory<WatchRecurringTransactions>(
      () => WatchRecurringTransactions(getIt<RecurringRepository>()),
    )
    ..registerFactory<GetRecurringTransaction>(
      () => GetRecurringTransaction(getIt<RecurringRepository>()),
    )
    ..registerFactory<SaveRecurringTransaction>(
      () => SaveRecurringTransaction(getIt<RecurringRepository>()),
    )
    ..registerFactory<DeleteRecurringTransaction>(
      () => DeleteRecurringTransaction(getIt<RecurringRepository>()),
    )
    ..registerFactory<SetRecurringArchived>(
      () => SetRecurringArchived(getIt<RecurringRepository>()),
    )
    ..registerFactory<SkipRecurringOccurrence>(
      () => SkipRecurringOccurrence(getIt<RecurringRepository>()),
    )
    ..registerFactory<ProcessDueRecurring>(
      () => ProcessDueRecurring(getIt<RecurringRepository>()),
    );
}
