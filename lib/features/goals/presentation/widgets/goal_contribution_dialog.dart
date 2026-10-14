import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/add_goal_contribution.dart';
import 'package:ledgerly/features/goals/domain/usecases/withdraw_from_goal.dart';
import 'package:ledgerly/features/goals/presentation/providers/goals_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

enum GoalContributionMode { deposit, withdraw }

/// Dialog or bottom sheet to deposit funds into or withdraw from a savings goal.
class GoalContributionDialog extends ConsumerStatefulWidget {
  const GoalContributionDialog({
    required this.goal,
    this.initialMode = GoalContributionMode.deposit,
    super.key,
  });

  final SavingsGoal goal;
  final GoalContributionMode initialMode;

  static Future<void> show(
    BuildContext context, {
    required SavingsGoal goal,
    GoalContributionMode initialMode = GoalContributionMode.deposit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          GoalContributionDialog(goal: goal, initialMode: initialMode),
    );
  }

  @override
  ConsumerState<GoalContributionDialog> createState() =>
      _GoalContributionDialogState();
}

class _GoalContributionDialogState
    extends ConsumerState<GoalContributionDialog> {
  late GoalContributionMode _mode;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _selectedAccountId;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rawText = _amountController.text.trim();
    if (rawText.isEmpty) {
      setState(() => _error = 'Please enter an amount');
      return;
    }

    final parsed = Money.tryParse(rawText, widget.goal.targetAmount.currency);
    if (parsed == null || parsed.amountMinor <= 0) {
      setState(() => _error = 'Amount must be greater than zero');
      return;
    }

    if (_mode == GoalContributionMode.withdraw &&
        parsed.amountMinor > widget.goal.currentAmount.amountMinor) {
      final strings = AppStrings.of(context);
      setState(() => _error = strings('goalWithdrawExceedsBalance'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    final strings = AppStrings.of(context);

    if (_mode == GoalContributionMode.deposit) {
      final useCase = ref.read(addGoalContributionProvider);
      final result = await useCase(
        AddGoalContributionParams(
          goalId: widget.goal.id,
          amountMinor: parsed.amountMinor,
          fromAccountId: _selectedAccountId,
          note: note,
        ),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      result.fold(
        onSuccess: (_) {
          AppFeedback.confirm(
            context,
            message: strings('goalContributedSuccess'),
          );
          Navigator.of(context).pop();
        },
        onErr: (f) => setState(() => _error = f.message),
      );
    } else {
      final useCase = ref.read(withdrawFromGoalProvider);
      final result = await useCase(
        WithdrawFromGoalParams(
          goalId: widget.goal.id,
          amountMinor: parsed.amountMinor,
          currentAmountMinor: widget.goal.currentAmount.amountMinor,
          toAccountId: _selectedAccountId,
          note: note,
        ),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      result.fold(
        onSuccess: (_) {
          AppFeedback.confirm(
            context,
            message: strings('goalWithdrawnSuccess'),
          );
          Navigator.of(context).pop();
        },
        onErr: (f) => setState(() => _error = f.message),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mode == GoalContributionMode.deposit
                          ? strings('depositTitle')
                          : strings('withdrawTitle'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.goal.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Current saved amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    strings('goalCurrentAmountLabel'),
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  AmountText(
                    widget.goal.currentAmount,
                    style: AmountStyle.row,
                    signed: false,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Deposit / Withdraw segment toggle
          SegmentedButton<GoalContributionMode>(
            segments: [
              ButtonSegment(
                value: GoalContributionMode.deposit,
                label: Text(strings('depositAction')),
                icon: const Icon(Icons.arrow_downward, size: 18),
              ),
              ButtonSegment(
                value: GoalContributionMode.withdraw,
                label: Text(strings('withdrawAction')),
                icon: const Icon(Icons.arrow_upward, size: 18),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selected) {
              setState(() {
                _mode = selected.first;
                _error = null;
              });
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Amount text field
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: strings('goalAmountLabel'),
              prefixText:
                  '${widget.goal.targetAmount.currency.name.toUpperCase()} ',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Optional Account selector
          accountsAsync.when(
            data: (accounts) {
              if (accounts.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: strings('goalAccountLabel'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None (General Saved)'),
                    ),
                    for (final acc in accounts)
                      DropdownMenuItem(value: acc.id, child: Text(acc.name)),
                  ],
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Optional Note text field
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: strings('goalNotesLabel'),
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Action button
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _mode == GoalContributionMode.deposit
                  ? colors.moneyIn
                  : colors.moneyOut,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _mode == GoalContributionMode.deposit
                        ? strings('depositAction')
                        : strings('withdrawAction'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
