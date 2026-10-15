import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/platform/window_size.dart';
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
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';
import '../domain/data_transfer_usecases_test.dart';

/// The data transfer screen, compact, light + dark (`docs/Design.md` §8).
///
/// All three tab notifiers are wired to a fake repository — without them each
/// tab resolves against unregistered DI, so the golden would pin the error
/// treatment of whichever tab paints first.
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('data_transfer_golden_test.dart'));

  late FakeDataTransferRepository repo;

  setUp(() => repo = FakeDataTransferRepository());

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) => pumpAppHost(
    tester,
    size: const Size(TestWidths.phone, 900),
    brightness: brightness,
    overrides: <Override>[
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

  group('DataTransfer screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DataTransferPage),
        matchesGoldenFile('goldens/data_transfer_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DataTransferPage),
        matchesGoldenFile('goldens/data_transfer_dark.png'),
      );
    });
  });
}
