import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/repositories/data_transfer_repository.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/create_full_backup.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/execute_import.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/export_transactions.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/parse_import_data.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/restore_full_backup.dart';

class FakeDataTransferRepository implements DataTransferRepository {
  ExportFilter? lastExportFilter;
  String? lastImportContent;
  ImportOptions? lastImportOptions;
  String? lastRestoreJson;
  RestoreMode? lastRestoreMode;

  @override
  Future<Result<ExportData>> exportTransactions(ExportFilter filter) async {
    lastExportFilter = filter;
    return const Success(
      ExportData(
        content: 'Date,Category,Amount,Currency,Direction,Note\n',
        format: ExportFormat.csv,
        filename: 'ledgerly_export.csv',
        recordCount: 1,
        totalIncomeMinor: 1000,
        totalExpenseMinor: 500,
        currencyCode: 'MMK',
      ),
    );
  }

  @override
  Future<Result<ImportPreview>> parseImportData({
    required String content,
    required ImportFormat format,
    ImportColumnMapping? customMapping,
  }) async {
    lastImportContent = content;
    return Success(
      ImportPreview(
        format: format,
        headers: ['Date', 'Category', 'Amount'],
        rows: [
          const ParsedImportRow(
            rowIndex: 1,
            rawValues: ['2026-10-14', 'Food', '5000'],
            date: 20261014,
            categoryName: 'Food',
            amountMinor: 500000,
            currency: 'MMK',
            direction: 'expense',
            isValid: true,
          ),
        ],
        mapping:
            customMapping ??
            const ImportColumnMapping({
              0: ImportFieldType.date,
              1: ImportFieldType.category,
              2: ImportFieldType.amount,
            }),
        newCategoryNames: [],
      ),
    );
  }

  @override
  Future<Result<ImportResult>> executeImport({
    required ImportPreview preview,
    required ImportOptions options,
  }) async {
    lastImportOptions = options;
    return const Success(
      ImportResult(
        importedCount: 1,
        skippedDuplicatesCount: 0,
        createdCategoriesCount: 0,
      ),
    );
  }

  @override
  Future<Result<String>> createFullBackup() async {
    return const Success('{"ledgerly_backup_version":1}');
  }

  @override
  Future<Result<RestoreResult>> restoreFullBackup({
    required String backupJson,
    required RestoreMode mode,
  }) async {
    lastRestoreJson = backupJson;
    lastRestoreMode = mode;
    return Success(
      RestoreResult(
        categoriesRestored: 5,
        transactionsRestored: 10,
        settingsRestored: 3,
        mode: mode,
      ),
    );
  }
}

void main() {
  late FakeDataTransferRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeDataTransferRepository();
  });

  group('Data Transfer Domain Use Cases', () {
    test('ExportTransactions delegates to repository', () async {
      final useCase = ExportTransactions(fakeRepository);
      const filter = ExportFilter(format: ExportFormat.csv);

      final result = await useCase(filter);

      expect(result.isSuccess, isTrue);
      expect(fakeRepository.lastExportFilter, equals(filter));
      final data = result.valueOrNull!;
      expect(data.recordCount, equals(1));
      expect(data.filename, equals('ledgerly_export.csv'));
    });

    test('ParseImportData delegates to repository', () async {
      final useCase = ParseImportData(fakeRepository);
      const params = ParseImportDataParams(
        content: 'Date,Category,Amount\n2026-10-14,Food,5000',
        format: ImportFormat.csv,
      );

      final result = await useCase(params);

      expect(result.isSuccess, isTrue);
      expect(fakeRepository.lastImportContent, equals(params.content));
      final preview = result.valueOrNull!;
      expect(preview.totalRows, equals(1));
      expect(preview.validRows, equals(1));
    });

    test('ExecuteImport delegates to repository', () async {
      final useCase = ExecuteImport(fakeRepository);
      const preview = ImportPreview(
        format: ImportFormat.csv,
        headers: ['Date'],
        rows: [],
        mapping: ImportColumnMapping({}),
        newCategoryNames: [],
      );
      const options = ImportOptions(skipDuplicates: true);

      final result = await useCase(
        const ExecuteImportParams(preview: preview, options: options),
      );

      expect(result.isSuccess, isTrue);
      expect(fakeRepository.lastImportOptions, equals(options));
      expect(result.valueOrNull!.importedCount, equals(1));
    });

    test('CreateFullBackup delegates to repository', () async {
      final useCase = CreateFullBackup(fakeRepository);

      final result = await useCase(const NoParams());

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, contains('"ledgerly_backup_version":1'));
    });

    test('RestoreFullBackup delegates to repository with mode', () async {
      final useCase = RestoreFullBackup(fakeRepository);
      const params = RestoreFullBackupParams(
        backupJson: '{"test":true}',
        mode: RestoreMode.merge,
      );

      final result = await useCase(params);

      expect(result.isSuccess, isTrue);
      expect(fakeRepository.lastRestoreJson, equals('{"test":true}'));
      expect(fakeRepository.lastRestoreMode, equals(RestoreMode.merge));
      expect(result.valueOrNull!.transactionsRestored, equals(10));
    });
  });
}
