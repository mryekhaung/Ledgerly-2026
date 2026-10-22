import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_bottom_sheet.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/add_goal_contribution.dart';
import 'package:ledgerly/features/goals/domain/usecases/withdraw_from_goal.dart';
import 'package:ledgerly/features/goals/presentation/providers/goals_providers.dart';
import 'package:ledgerly/features/goals/presentation/widgets/contribution/form.dart';
import 'package:ledgerly/features/goals/presentation/widgets/contribution/header.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Deposit or withdraw mode.
enum GoalContributionMode { deposit, withdraw }

/// Dialog or bottom sheet to deposit funds into or withdraw from a savings goal.
///
/// Composition root only: header and form live in `widgets/contribution/`
/// (`docs/Conventions.md` §1).
class GoalContributionDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const GoalContributionDialog({
    required this.goal,
    this.initialMode = GoalContributionMode.deposit,
    super.key,
  });

  /// The goal being adjusted.
  final SavingsGoal goal;

  /// The starting mode.
  final GoalContributionMode initialMode;

  /// Shows the dialog as a bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required SavingsGoal goal,
    GoalContributionMode initialMode = GoalContributionMode.deposit,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
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
    final strings = AppStrings.of(context);
    final rawText = _amountController.text.trim();
    if (rawText.isEmpty) {
      setState(() => _error = strings('goalAmountRequired'));
      return;
    }

    final parsed = Money.tryParse(rawText, widget.goal.targetAmount.currency);
    if (parsed == null || parsed.amountMinor <= 0) {
      setState(
        () => _error = strings(
          _mode == GoalContributionMode.deposit
              ? 'goalContributionAmountInvalid'
              : 'goalWithdrawAmountInvalid',
        ),
      );
      return;
    }

    if (_mode == GoalContributionMode.withdraw &&
        parsed.amountMinor > widget.goal.currentAmount.amountMinor) {
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
        borderRadius: const BorderRadius.vertical(top: AppRadius.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle for Material
          if (AppPlatform.resolve().usesMaterial)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: AppRadius.borderSm,
                ),
              ),
            ),

          ContributionHeader(mode: _mode, goal: widget.goal),

          const SizedBox(height: AppSpacing.md),

          ContributionForm(
            mode: _mode,
            onModeChanged: (mode) {
              setState(() {
                _mode = mode;
                _error = null;
              });
            },
            amountController: _amountController,
            amountError: _error,
            amountLabel: strings('goalAmountLabel'),
            currencyPrefix:
                '${widget.goal.targetAmount.currency.name.toUpperCase()} ',
            accounts: accountsAsync,
            selectedAccountId: _selectedAccountId,
            onAccountChanged: (val) => setState(() => _selectedAccountId = val),
            noteController: _noteController,
          ),

          // Action button
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _mode == GoalContributionMode.deposit
                  ? colors.moneyIn
                  : colors.moneyOut,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
