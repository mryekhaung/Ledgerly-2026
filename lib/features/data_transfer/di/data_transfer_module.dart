import 'package:get_it/get_it.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/features/data_transfer/data/datasources/data_transfer_local_datasource.dart';
import 'package:ledgerly/features/data_transfer/data/repositories/data_transfer_repository_impl.dart';
import 'package:ledgerly/features/data_transfer/domain/repositories/data_transfer_repository.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/create_full_backup.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/execute_import.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/export_transactions.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/parse_import_data.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/restore_full_backup.dart';

void registerDataTransferModule(GetIt getIt) {
  // Data Source
  getIt.registerLazySingleton<DataTransferLocalDataSource>(
    () => DataTransferLocalDataSource(db: getIt<AppDatabase>()),
  );

  // Repository
  getIt.registerLazySingleton<DataTransferRepository>(
    () => DataTransferRepositoryImpl(getIt<DataTransferLocalDataSource>()),
  );

  // Use Cases
  getIt.registerFactory<ExportTransactions>(
    () => ExportTransactions(getIt<DataTransferRepository>()),
  );
  getIt.registerFactory<ParseImportData>(
    () => ParseImportData(getIt<DataTransferRepository>()),
  );
  getIt.registerFactory<ExecuteImport>(
    () => ExecuteImport(getIt<DataTransferRepository>()),
  );
  getIt.registerFactory<CreateFullBackup>(
    () => CreateFullBackup(getIt<DataTransferRepository>()),
  );
  getIt.registerFactory<RestoreFullBackup>(
    () => RestoreFullBackup(getIt<DataTransferRepository>()),
  );
}
