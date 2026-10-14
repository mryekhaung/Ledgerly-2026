import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/data_transfer/data/datasources/data_transfer_local_datasource.dart';
import 'package:ledgerly/features/data_transfer/data/repositories/data_transfer_repository_impl.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';

import '../../../core/database/db_harness.dart';

void main() {
  group('DataTransferRepositoryImpl with real SQLite', () {
    late DbHarness harness;
    late DataTransferLocalDataSource localDataSource;
    late DataTransferRepositoryImpl repository;

    setUp(() async {
      harness = useDbHarness();
      localDataSource = DataTransferLocalDataSource(
        db: harness.db,
        clock: harness.clock,
      );
      repository = DataTransferRepositoryImpl(localDataSource);

      // Seed starter category
      await harness.db.categoriesDao.insert(
        name: 'Food',
        iconKey: 'restaurant',
        colorValue: 0xFFFF5722,
        kind: 'expense',
      );
    });

    test('exportTransactions outputs CSV with headers and rows', () async {
      final categories = await localDataSource.getActiveCategories();
      final foodCategory = categories.firstWhere((c) => c.name == 'Food');

      await harness.db.transactionsDao.insert(
        categoryId: foodCategory.id,
        amountMinor: 350000,
        currency: 'mmk',
        direction: 'expense',
        date: LocalDate(2026, 10, 14),
        note: 'Tasty ramen',
      );

      final result = await repository.exportTransactions(
        const ExportFilter(format: ExportFormat.csv),
      );

      expect(result.isSuccess, isTrue);
      final exportData = result.valueOrNull!;
      expect(exportData.recordCount, equals(1));
      expect(exportData.totalExpenseMinor, equals(350000));
      expect(exportData.content, contains('Date,Category,Amount'));
      expect(exportData.content, contains('Food'));
      expect(exportData.content, contains('Tasty ramen'));
    });

    test('exportTransactions outputs JSON array', () async {
      final categories = await localDataSource.getActiveCategories();
      final foodCategory = categories.firstWhere((c) => c.name == 'Food');

      await harness.db.transactionsDao.insert(
        categoryId: foodCategory.id,
        amountMinor: 5000,
        currency: 'usd',
        direction: 'expense',
        date: LocalDate(2026, 10, 14),
      );

      final result = await repository.exportTransactions(
        const ExportFilter(format: ExportFormat.json),
      );

      expect(result.isSuccess, isTrue);
      final exportData = result.valueOrNull!;
      expect(exportData.recordCount, equals(1));
      expect(exportData.content, contains('"category": "Food"'));
    });

    test(
      'parseImportData parses CSV, detects categories and duplicate rows',
      () async {
        final categories = await localDataSource.getActiveCategories();
        final foodCategory = categories.firstWhere((c) => c.name == 'Food');

        // Seed an existing transaction
        await harness.db.transactionsDao.insert(
          categoryId: foodCategory.id,
          amountMinor: 200000,
          currency: 'mmk',
          direction: 'expense',
          date: LocalDate(2026, 10, 14),
          note: 'Coffee',
        );

        const csvContent = '''
Date,Category,Amount,Currency,Direction,Note
2026-10-14,Food,2000.00,MMK,expense,Coffee
2026-10-15,Transport,1500.00,MMK,expense,Bus fare
''';

        final result = await repository.parseImportData(
          content: csvContent,
          format: ImportFormat.csv,
        );

        expect(result.isSuccess, isTrue);
        final preview = result.valueOrNull!;
        expect(preview.totalRows, equals(2));
        expect(preview.rows[0].isDuplicate, isTrue); // Coffee was already in DB
        expect(preview.rows[1].isDuplicate, isFalse);
        expect(preview.newCategoryNames, contains('Transport'));
      },
    );

    test(
      'executeImport commits rows and auto-creates missing categories',
      () async {
        const csvContent = '''
Date,Category,Amount,Currency,Direction,Note
2026-10-16,Utilities,12000.00,MMK,expense,Electricity
''';

        final parseResult = await repository.parseImportData(
          content: csvContent,
          format: ImportFormat.csv,
        );
        final preview = parseResult.valueOrNull!;

        final importResult = await repository.executeImport(
          preview: preview,
          options: const ImportOptions(
            autoCreateCategories: true,
            skipDuplicates: true,
          ),
        );

        expect(importResult.isSuccess, isTrue);
        expect(importResult.valueOrNull!.importedCount, equals(1));
        expect(importResult.valueOrNull!.createdCategoriesCount, equals(1));

        // Verify category was created
        final categories = await localDataSource.getActiveCategories();
        expect(categories.any((c) => c.name == 'Utilities'), isTrue);

        // Verify transaction was inserted
        final txns = await localDataSource.getTransactionsForExport(
          const ExportFilter(),
        );
        expect(txns.any((t) => t.note == 'Electricity'), isTrue);
      },
    );

    test(
      'createFullBackup and restoreFullBackup round-trip in overwrite mode',
      () async {
        await harness.db.appSettingsDao.put(key: 'theme_mode', value: 'dark');

        final backupResult = await repository.createFullBackup();
        expect(backupResult.isSuccess, isTrue);
        final backupJson = backupResult.valueOrNull!;

        expect(backupJson, contains('"ledgerly_backup_version": 1'));
        expect(backupJson, contains('"theme_mode": "dark"'));

        // Restore with overwrite mode
        final restoreResult = await repository.restoreFullBackup(
          backupJson: backupJson,
          mode: RestoreMode.overwrite,
        );

        expect(restoreResult.isSuccess, isTrue);
        final summary = restoreResult.valueOrNull!;
        expect(summary.categoriesRestored, greaterThanOrEqualTo(1));
        expect(summary.settingsRestored, greaterThanOrEqualTo(1));

        // Verify setting was preserved
        final theme = await harness.db.appSettingsDao.read('theme_mode');
        expect(theme, equals('dark'));
      },
    );
  });
}
