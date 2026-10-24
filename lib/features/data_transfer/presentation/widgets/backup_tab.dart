import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/app_text_field.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/presentation/providers/data_transfer_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// The Backup/Restore tab: create backup, paste payload, restore mode, run.
///
/// Owns its text controller and restore-mode selection — the page only owns
/// the top-level tab index. Extracted from `data_transfer_page.dart`
/// (`docs/Conventions.md` §1).
class BackupTab extends ConsumerStatefulWidget {
  /// Creates a [BackupTab].
  const BackupTab({super.key});

  @override
  ConsumerState<BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends ConsumerState<BackupTab> {
  final TextEditingController _restoreTextController = TextEditingController();
  RestoreMode _restoreMode = RestoreMode.merge;

  @override
  void dispose() {
    _restoreTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
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
                    ?.copyWith(fontWeight: FontWeight.w600),
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
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
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
                  AppStrings.fill(context, 'backupMetadataSummary', {
                    'categories': state.loadedMetadata!.categoryCount,
                    'transactions': state.loadedMetadata!.transactionCount,
                  }),
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
