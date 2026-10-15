import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/data_transfer_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// The Import tab: format, paste box, preview, options, execute.
///
/// Extracted from `data_transfer_page.dart` (`docs/Conventions.md` §1).
class ImportTab extends ConsumerWidget {
  /// Creates an [ImportTab].
  const ImportTab({required this.textController, super.key});

  /// Owned by the parent (created/disposed with the page).
  final TextEditingController textController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
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
          onChanged: notifier.setFormat,
          tabs: const [
            SegmentedTab(value: ImportFormat.csv, label: 'CSV'),
            SegmentedTab(value: ImportFormat.json, label: 'JSON'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: textController,
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
                  textController.text = data!.text!;
                }
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: strings('importActionParse'),
              isLoading: importState.isParsing,
              onPressed: () async {
                final text = textController.text.trim();
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
                      ?.copyWith(fontWeight: FontWeight.w600),
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
                textController.clear();
              }
            },
          ),
        ],
      ],
    );
  }
}
