import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/create_full_backup.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/execute_import.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/export_transactions.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/parse_import_data.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/restore_full_backup.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/backup_restore_notifier.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/data_transfer_providers.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/export_notifier.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/import_notifier.dart';

import '../domain/data_transfer_usecases_test.dart';

void main() {
  group('Data Transfer Notifiers', () {
    late FakeDataTransferRepository repository;

    setUp(() {
      repository = FakeDataTransferRepository();
    });

    test(
      'ExportNotifier updates format and preset, and performs export',
      () async {
        final container = ProviderContainer(
          overrides: [
            exportNotifierProvider.overrideWith(
              () =>
                  ExportNotifier(exportUseCase: ExportTransactions(repository)),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(exportNotifierProvider.notifier);

        notifier.setFormat(ExportFormat.json);
        expect(
          container.read(exportNotifierProvider).filter.format,
          equals(ExportFormat.json),
        );

        notifier.setRangePreset(ExportRangePreset.lastPeriod);
        expect(
          container.read(exportNotifierProvider).filter.rangePreset,
          equals(ExportRangePreset.lastPeriod),
        );

        await notifier.export();

        final state = container.read(exportNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.exportedData, isNotNull);
        expect(state.exportedData!.filename, equals('ledgerly_export.csv'));
      },
    );

    test('ImportNotifier switches format when setFormat is called', () async {
      final container = ProviderContainer(
        overrides: [
          importNotifierProvider.overrideWith(
            () => ImportNotifier(
              parseUseCase: ParseImportData(repository),
              executeUseCase: ExecuteImport(repository),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(importNotifierProvider.notifier);
      expect(
        container.read(importNotifierProvider).format,
        equals(ImportFormat.csv),
      );

      notifier.setFormat(ImportFormat.json);

      expect(
        container.read(importNotifierProvider).format,
        equals(ImportFormat.json),
      );
    });

    test('ImportNotifier parses content and executes import', () async {
      final container = ProviderContainer(
        overrides: [
          importNotifierProvider.overrideWith(
            () => ImportNotifier(
              parseUseCase: ParseImportData(repository),
              executeUseCase: ExecuteImport(repository),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(importNotifierProvider.notifier);

      await notifier.loadAndParse(
        content: 'Date,Category,Amount\n2026-10-14,Food,5000',
        format: ImportFormat.csv,
      );

      var state = container.read(importNotifierProvider);
      expect(state.isParsing, isFalse);
      expect(state.preview, isNotNull);
      expect(state.preview!.totalRows, equals(1));

      await notifier.executeImport();

      state = container.read(importNotifierProvider);
      expect(state.isImporting, isFalse);
      expect(state.result, isNotNull);
      expect(state.result!.importedCount, equals(1));
    });

    test('BackupRestoreNotifier creates and restores backup', () async {
      final container = ProviderContainer(
        overrides: [
          backupRestoreNotifierProvider.overrideWith(
            () => BackupRestoreNotifier(
              createUseCase: CreateFullBackup(repository),
              restoreUseCase: RestoreFullBackup(repository),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(backupRestoreNotifierProvider.notifier);

      await notifier.createBackup();

      var state = container.read(backupRestoreNotifierProvider);
      expect(state.isCreatingBackup, isFalse);
      expect(state.backupJson, contains('ledgerly_backup_version'));

      await notifier.restoreBackup(mode: RestoreMode.overwrite);

      state = container.read(backupRestoreNotifierProvider);
      expect(state.isRestoring, isFalse);
      expect(state.restoreResult, isNotNull);
      expect(state.restoreResult!.transactionsRestored, equals(10));
    });
  });
}
