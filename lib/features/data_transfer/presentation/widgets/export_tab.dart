import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/data_transfer_providers.dart';
import 'package:ledgerly/features/data_transfer/presentation/widgets/preset_chip.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// The Export tab: format, range preset, preview summary, export action.
///
/// Extracted from `data_transfer_page.dart` (`docs/Conventions.md` §1).
class ExportTab extends ConsumerWidget {
  /// Creates an [ExportTab].
  const ExportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
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
            PresetChip(
              label: strings('exportPresetThisPeriod'),
              isSelected:
                  exportState.filter.rangePreset ==
                  ExportRangePreset.thisPeriod,
              onSelected: () =>
                  notifier.setRangePreset(ExportRangePreset.thisPeriod),
            ),
            PresetChip(
              label: strings('exportPresetLastPeriod'),
              isSelected:
                  exportState.filter.rangePreset ==
                  ExportRangePreset.lastPeriod,
              onSelected: () =>
                  notifier.setRangePreset(ExportRangePreset.lastPeriod),
            ),
            PresetChip(
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
                      ?.copyWith(fontWeight: FontWeight.w600),
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
          label: strings('exportActionExport'),
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
}
