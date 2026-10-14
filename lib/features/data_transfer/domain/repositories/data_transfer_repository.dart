import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';

/// Pure Dart repository interface for data export, import, and full backup/restore.
abstract class DataTransferRepository {
  /// Exports transactions matching [filter] as CSV or JSON.
  Future<Result<ExportData>> exportTransactions(ExportFilter filter);

  /// Parses [content] (CSV string or JSON string) and returns an [ImportPreview].
  Future<Result<ImportPreview>> parseImportData({
    required String content,
    required ImportFormat format,
    ImportColumnMapping? customMapping,
  });

  /// Commits parsed import rows to the local database with [options].
  Future<Result<ImportResult>> executeImport({
    required ImportPreview preview,
    required ImportOptions options,
  });

  /// Generates a full Ledgerly backup JSON archive string.
  Future<Result<String>> createFullBackup();

  /// Restores a backup from [backupJson] using the specified [mode].
  Future<Result<RestoreResult>> restoreFullBackup({
    required String backupJson,
    required RestoreMode mode,
  });
}
