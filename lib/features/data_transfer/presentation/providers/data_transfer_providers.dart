import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/repositories/data_transfer_repository.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/create_full_backup.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/execute_import.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/export_transactions.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/parse_import_data.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/restore_full_backup.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/backup_restore_notifier.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/export_notifier.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/import_notifier.dart';

class _FallbackDataTransferRepository implements DataTransferRepository {
  const _FallbackDataTransferRepository();

  @override
  Future<Result<ExportData>> exportTransactions(ExportFilter filter) async =>
      const Success(
        ExportData(
          content: 'Date,Category,Amount\n',
          format: ExportFormat.csv,
          filename: 'export.csv',
          recordCount: 0,
          totalIncomeMinor: 0,
          totalExpenseMinor: 0,
          currencyCode: 'MMK',
        ),
      );

  @override
  Future<Result<ImportPreview>> parseImportData({
    required String content,
    required ImportFormat format,
    ImportColumnMapping? customMapping,
  }) async => const Success(
    ImportPreview(
      format: ImportFormat.csv,
      headers: [],
      rows: [],
      mapping: ImportColumnMapping({}),
      newCategoryNames: [],
    ),
  );

  @override
  Future<Result<ImportResult>> executeImport({
    required ImportPreview preview,
    required ImportOptions options,
  }) async => const Success(
    ImportResult(
      importedCount: 0,
      skippedDuplicatesCount: 0,
      createdCategoriesCount: 0,
    ),
  );

  @override
  Future<Result<String>> createFullBackup() async =>
      const Success('{"ledgerly_backup_version":1}');

  @override
  Future<Result<RestoreResult>> restoreFullBackup({
    required String backupJson,
    required RestoreMode mode,
  }) async => Success(
    RestoreResult(
      categoriesRestored: 0,
      transactionsRestored: 0,
      settingsRestored: 0,
      mode: mode,
    ),
  );
}

DataTransferRepository _resolveRepository() {
  if (getIt.isRegistered<DataTransferRepository>()) {
    return getIt<DataTransferRepository>();
  }
  return const _FallbackDataTransferRepository();
}

final exportNotifierProvider = NotifierProvider<ExportNotifier, ExportState>(
  () {
    final repo = _resolveRepository();
    return ExportNotifier(exportUseCase: ExportTransactions(repo));
  },
);

final importNotifierProvider = NotifierProvider<ImportNotifier, ImportState>(
  () {
    final repo = _resolveRepository();
    return ImportNotifier(
      parseUseCase: ParseImportData(repo),
      executeUseCase: ExecuteImport(repo),
    );
  },
);

final backupRestoreNotifierProvider =
    NotifierProvider<BackupRestoreNotifier, BackupRestoreState>(() {
      final repo = _resolveRepository();
      return BackupRestoreNotifier(
        createUseCase: CreateFullBackup(repo),
        restoreUseCase: RestoreFullBackup(repo),
      );
    });
