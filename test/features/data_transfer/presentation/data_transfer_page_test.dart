import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/create_full_backup.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/execute_import.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/export_transactions.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/parse_import_data.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/restore_full_backup.dart';
import 'package:ledgerly/features/data_transfer/presentation/pages/data_transfer_page.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/backup_restore_notifier.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/data_transfer_providers.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/export_notifier.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/import_notifier.dart';

import '../../../support/app_test_host.dart';
import '../domain/data_transfer_usecases_test.dart';

void main() {
  group('DataTransferPage', () {
    late FakeDataTransferRepository repo;

    setUp(() {
      repo = FakeDataTransferRepository();
    });

    testWidgets(
      'renders tabs and switches between Export, Import, and Backup',
      (tester) async {
        await pumpAppHost(
          tester,
          overrides: [
            exportNotifierProvider.overrideWith(
              () => ExportNotifier(exportUseCase: ExportTransactions(repo)),
            ),
            importNotifierProvider.overrideWith(
              () => ImportNotifier(
                parseUseCase: ParseImportData(repo),
                executeUseCase: ExecuteImport(repo),
              ),
            ),
            backupRestoreNotifierProvider.overrideWith(
              () => BackupRestoreNotifier(
                createUseCase: CreateFullBackup(repo),
                restoreUseCase: RestoreFullBackup(repo),
              ),
            ),
          ],
          home: const DataTransferPage(),
        );
        await tester.pumpAndSettle();

        // Top segmented tabs for the 3 modes
        expect(find.text('Export'), findsWidgets);
        expect(find.text('Import'), findsWidgets);
        expect(find.text('Backup'), findsWidgets);

        // Initially on Export tab
        expect(find.text('Format'), findsWidgets);
        expect(find.text('Date Range'), findsOneWidget);
        expect(find.text('All Time'), findsOneWidget);
        expect(find.text('This Period'), findsOneWidget);
        expect(find.text('Last Period'), findsOneWidget);

        // Tap on Export & Copy button
        await tester.tap(find.text('Export & Copy'));
        await tester.pumpAndSettle();

        // Shows exported summary
        expect(find.text('Export Summary'), findsOneWidget);
        expect(find.text('Income'), findsOneWidget);
        expect(find.text('Expense'), findsOneWidget);

        // Switch to Import tab
        await tester.tap(find.text('Import').first);
        await tester.pumpAndSettle();

        expect(find.text('Paste'), findsOneWidget);
        expect(find.text('Parse Data'), findsOneWidget);

        // Switch to Backup tab
        await tester.tap(find.text('Backup').first);
        await tester.pumpAndSettle();

        expect(find.text('Full App Backup'), findsOneWidget);
        expect(find.text('Create Full Backup'), findsOneWidget);
        expect(find.text('Restore from Backup'), findsOneWidget);
        expect(find.text('Load Backup'), findsOneWidget);
      },
    );
  });
}
