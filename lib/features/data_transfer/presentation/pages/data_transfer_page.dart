import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/data_transfer_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// Hub page for data management: Export, Import, and Full Backup/Restore.
class DataTransferPage extends ConsumerStatefulWidget {
  const DataTransferPage({super.key});

  @override
  ConsumerState<DataTransferPage> createState() => _DataTransferPageState();
}

class _DataTransferPageState extends ConsumerState<DataTransferPage> {
  int _selectedTabIndex = 0;
  final TextEditingController _importTextController = TextEditingController();
  final TextEditingController _restoreTextController = TextEditingController();
  RestoreMode _restoreMode = RestoreMode.merge;

  @override
  void dispose() {
    _importTextController.dispose();
    _restoreTextController.dispose();
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
                0 => _buildExportTab(context, ref, strings),
                1 => _buildImportTab(context, ref, strings),
                _ => _buildBackupTab(context, ref, strings),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportTab(
    BuildContext context,
    WidgetRef ref,
    String Function(String) strings,
  ) {
    final exportState = ref.watch(exportNotifierProvider);
    final notifier = ref.read(exportNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings('exportFormatLabel'),
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedTabs<ExportFormat>(
          selected: exportState.filter.format,
          onChanged: notifier.setFormat,
          tabs: const [
            SegmentedTab(value: ExportFormat.csv, label: 'CSV'),
            SegmentedTab(value: ExportFormat.json, label: 'JSON'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings('exportRangeLabel'),
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            _PresetChip(
              label: strings('exportPresetThisPeriod'),
              isSelected:
                  exportState.filter.rangePreset ==
                  ExportRangePreset.thisPeriod,
              onSelected: () =>
                  notifier.setRangePreset(ExportRangePreset.thisPeriod),
            ),
            _PresetChip(
              label: strings('exportPresetLastPeriod'),
              isSelected:
                  exportState.filter.rangePreset ==
                  ExportRangePreset.lastPeriod,
              onSelected: () =>
                  notifier.setRangePreset(ExportRangePreset.lastPeriod),
            ),
            _PresetChip(
              label: strings('exportPresetAllTime'),
              isSelected:
                  exportState.filter.rangePreset == ExportRangePreset.allTime,
              onSelected: () =>
                  notifier.setRangePreset(ExportRangePreset.allTime),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (exportState.exportedData != null) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings('exportSummaryTitle'),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(strings('exportTotalRecords')),
                    Text(
                      '${exportState.exportedData!.recordCount}',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(strings('exportTotalIncome')),
                    AmountText(
                      Money.minor(
                        exportState.exportedData!.totalIncomeMinor,
                        CurrencyCode.tryParse(
                              exportState.exportedData!.currencyCode,
                            ) ??
                            CurrencyCode.mmk,
                      ),
                      signed: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(strings('exportTotalExpense')),
                    AmountText(
                      Money.minor(
                        exportState.exportedData!.totalExpenseMinor,
                        CurrencyCode.tryParse(
                              exportState.exportedData!.currencyCode,
                            ) ??
                            CurrencyCode.mmk,
                      ),
                      signed: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppButton(
          label: exportState.exportedData == null
              ? strings('exportActionExport')
              : strings('exportActionExport'),
          isLoading: exportState.isLoading,
          onPressed: () async {
            await notifier.export();
            final data = ref.read(exportNotifierProvider).exportedData;
            if (data != null && context.mounted) {
              await Clipboard.setData(ClipboardData(text: data.content));
              notifier.markCopied(true);
              if (context.mounted) {
                AppFeedback.confirm(
                  context,
                  message: strings('exportSuccessCopied'),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildImportTab(
    BuildContext context,
    WidgetRef ref,
    String Function(String) strings,
  ) {
    final colors = AppThemeColors.of(context);
    final importState = ref.watch(importNotifierProvider);
    final notifier = ref.read(importNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings('importSourceLabel'),
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedTabs<ImportFormat>(
          selected: importState.format,
          onChanged: (fmt) {
            notifier.updateOptions(importState.options);
          },
          tabs: const [
            SegmentedTab(value: ImportFormat.csv, label: 'CSV'),
            SegmentedTab(value: ImportFormat.json, label: 'JSON'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _importTextController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: strings('importPasteHint'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(AppIcons.paste, size: 18),
              label: Text(strings('dataTransferPaste')),
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  _importTextController.text = data!.text!;
                }
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: strings('importActionParse'),
              isLoading: importState.isParsing,
              onPressed: () async {
                final text = _importTextController.text.trim();
                if (text.isNotEmpty) {
                  await notifier.loadAndParse(
                    content: text,
                    format: importState.format,
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (importState.preview != null) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings('importPreviewTitle'),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(strings('importTotalRows')),
                    Text('${importState.preview!.totalRows}'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(strings('importValidRows')),
                    Text(
                      '${importState.preview!.validRows}',
                      style: AppTypography.caption.copyWith(
                        color: colors.moneyIn,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(strings('importDuplicateRows')),
                    Text(
                      '${importState.preview!.duplicateRows}',
                      style: AppTypography.caption.copyWith(
                        color: importState.preview!.duplicateRows > 0
                            ? colors.warning
                            : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (importState.preview!.newCategoryNames.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(strings('importNewCategories')),
                      Text(
                        '${importState.preview!.newCategoryNames.length}',
                        style: AppTypography.caption.copyWith(
                          color: colors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: importState.options.skipDuplicates,
            title: Text(strings('importSkipDuplicates')),
            onChanged: (val) {
              notifier.updateOptions(
                importState.options.copyWith(skipDuplicates: val),
              );
            },
          ),
          SwitchListTile(
            value: importState.options.autoCreateCategories,
            title: Text(strings('importAutoCreateCategories')),
            onChanged: (val) {
              notifier.updateOptions(
                importState.options.copyWith(autoCreateCategories: val),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: strings('importActionExecute'),
            isLoading: importState.isImporting,
            onPressed: () async {
              await notifier.executeImport();
              final res = ref.read(importNotifierProvider).result;
              if (res != null && context.mounted) {
                AppFeedback.confirm(context, message: strings('importSuccess'));
                _importTextController.clear();
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildBackupTab(
    BuildContext context,
    WidgetRef ref,
    String Function(String) strings,
  ) {
    final state = ref.watch(backupRestoreNotifierProvider);
    final notifier = ref.read(backupRestoreNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings('backupTitle'),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                strings('backupDescription'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: strings('backupActionCreate'),
                isLoading: state.isCreatingBackup,
                onPressed: () async {
                  await notifier.createBackup();
                  final json = ref
                      .read(backupRestoreNotifierProvider)
                      .backupJson;
                  if (json != null && context.mounted) {
                    await Clipboard.setData(ClipboardData(text: json));
                    if (context.mounted) {
                      AppFeedback.confirm(
                        context,
                        message: strings('backupCreatedSuccess'),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings('restoreTitle'),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _restoreTextController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: strings('restorePasteHint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(AppIcons.paste, size: 18),
                    label: Text(strings('dataTransferPaste')),
                    onPressed: () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (data?.text != null) {
                        _restoreTextController.text = data!.text!;
                      }
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: strings('restoreActionParse'),
                    onPressed: () {
                      final text = _restoreTextController.text.trim();
                      if (text.isNotEmpty) {
                        notifier.loadBackupPayload(text);
                      }
                    },
                  ),
                ],
              ),
              if (state.loadedMetadata != null) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                Text(
                  'Backup Metadata: ${state.loadedMetadata!.categoryCount} categories, ${state.loadedMetadata!.transactionCount} transactions',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedTabs<RestoreMode>(
                  selected: _restoreMode,
                  tabs: [
                    SegmentedTab<RestoreMode>(
                      value: RestoreMode.merge,
                      label: strings('restoreModeMerge'),
                    ),
                    SegmentedTab<RestoreMode>(
                      value: RestoreMode.overwrite,
                      label: strings('restoreModeOverwrite'),
                    ),
                  ],
                  onChanged: (mode) => setState(() => _restoreMode = mode),
                ),
                if (_restoreMode == RestoreMode.overwrite) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    strings('restoreOverwriteWarning'),
                    style: AppTypography.label.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: strings('restoreActionExecute'),
                  isLoading: state.isRestoring,
                  onPressed: () async {
                    await notifier.restoreBackup(mode: _restoreMode);
                    final res = ref
                        .read(backupRestoreNotifierProvider)
                        .restoreResult;
                    if (res != null && context.mounted) {
                      AppFeedback.confirm(
                        context,
                        message: strings('restoreSuccess'),
                      );
                      _restoreTextController.clear();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
