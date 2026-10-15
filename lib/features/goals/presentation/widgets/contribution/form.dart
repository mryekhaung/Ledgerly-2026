import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_contribution_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Mode toggle, amount, account and note fields.
///
/// Extracted from `goal_contribution_dialog.dart` (`docs/Conventions.md` §1).
class ContributionForm extends StatelessWidget {
  /// Creates a [ContributionForm].
  const ContributionForm({
    required this.mode,
    required this.onModeChanged,
    required this.amountController,
    required this.amountError,
    required this.amountLabel,
    required this.currencyPrefix,
    required this.accounts,
    required this.selectedAccountId,
    required this.onAccountChanged,
    required this.noteController,
    super.key,
  });

  /// Deposit or withdraw.
  final GoalContributionMode mode;

  /// Called with the new mode.
  final ValueChanged<GoalContributionMode> onModeChanged;

  /// The amount field controller (owned by the dialog).
  final TextEditingController amountController;

  /// The amount validation error, if any.
  final String? amountError;

  /// The amount field label.
  final String amountLabel;

  /// The currency prefix text.
  final String currencyPrefix;

  /// The accounts for the dropdown (async: loading renders nothing).
  final AsyncValue<List<Account>> accounts;

  /// The linked account id, if any.
  final String? selectedAccountId;

  /// Called with the picked account id (null clears).
  final ValueChanged<String?> onAccountChanged;

  /// The note field controller (owned by the dialog).
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Deposit / Withdraw segment toggle
        SegmentedTabs<GoalContributionMode>(
          tabs: [
            SegmentedTab(
              value: GoalContributionMode.deposit,
              label: strings('depositAction'),
              icon: AppIcons.decrease,
            ),
            SegmentedTab(
              value: GoalContributionMode.withdraw,
              label: strings('withdrawAction'),
              icon: AppIcons.increase,
            ),
          ],
          selected: mode,
          onChanged: onModeChanged,
        ),

        const SizedBox(height: AppSpacing.md),

        // Amount text field
        TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: amountLabel,
            prefixText: currencyPrefix,
            border: const OutlineInputBorder(),
            errorText: amountError,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Optional Account selector
        accounts.when(
          data: (accounts) {
            if (accounts.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: DropdownButtonFormField<String?>(
                initialValue: selectedAccountId,
                decoration: InputDecoration(
                  labelText: strings('goalAccountLabel'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(strings('goalNoAccountOption')),
                  ),
                  for (final acc in accounts)
                    DropdownMenuItem(value: acc.id, child: Text(acc.name)),
                ],
                onChanged: onAccountChanged,
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // Optional Note text field
        TextField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: strings('goalNotesLabel'),
            border: const OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
