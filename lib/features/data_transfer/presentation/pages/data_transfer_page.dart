import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/data_transfer/presentation/widgets/backup_tab.dart';
import 'package:ledgerly/features/data_transfer/presentation/widgets/export_tab.dart';
import 'package:ledgerly/features/data_transfer/presentation/widgets/import_tab.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// Hub page for data management: Export, Import, and Full Backup/Restore.
///
/// Composition root only: the three tabs live in `widgets/`
/// (`docs/Conventions.md` §1).
class DataTransferPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const DataTransferPage({super.key});

  @override
  ConsumerState<DataTransferPage> createState() => _DataTransferPageState();
}

class _DataTransferPageState extends ConsumerState<DataTransferPage> {
  int _selectedTabIndex = 0;
  final TextEditingController _importTextController = TextEditingController();

  @override
  void dispose() {
    _importTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AppScaffold(
      title: strings('dataTransferTitle'),
      body: ConstrainedPane(
        maxWidth: 720,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedTabs<int>(
                selected: _selectedTabIndex,
                onChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                tabs: [
                  SegmentedTab(
                    value: 0,
                    label: strings('dataTransferTabExport'),
                  ),
                  SegmentedTab(
                    value: 1,
                    label: strings('dataTransferTabImport'),
                  ),
                  SegmentedTab(
                    value: 2,
                    label: strings('dataTransferTabBackup'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              switch (_selectedTabIndex) {
                0 => const ExportTab(),
                1 => ImportTab(textController: _importTextController),
                _ => const BackupTab(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
