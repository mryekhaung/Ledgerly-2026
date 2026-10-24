import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_date_picker.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/app_text_field.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/goals/presentation/providers/goals_providers.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_form/basics_section.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_form/date_account_section.dart';
import 'package:ledgerly/features/goals/presentation/widgets/goal_form/icon_color_section.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Page for creating or editing a savings goal.
///
/// Composition root only: sections live in `widgets/goal_form/`
/// (`docs/Conventions.md` §1).
class GoalFormPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const GoalFormPage({this.goalId, super.key});

  /// The goal being edited, or null when creating.
  final String? goalId;

  @override
  ConsumerState<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends ConsumerState<GoalFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _currentAmountController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _targetAmountController = TextEditingController();
    _currentAmountController = TextEditingController();
    _notesController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initForm());
  }

  Future<void> _initForm() async {
    final notifier = ref.read(goalFormProvider.notifier);
    if (widget.goalId != null) {
      final goal = await ref.read(goalByIdProvider(widget.goalId!).future);
      if (goal != null && mounted) {
        notifier.init(goal);
        _nameController.text = goal.name;
        _targetAmountController.text = '${goal.targetAmount.amountMinor}';
        _currentAmountController.text = '${goal.currentAmount.amountMinor}';
        _notesController.text = goal.notes ?? '';
      }
    } else {
      notifier.init(null);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final state = ref.read(goalFormProvider);
    final now = DateTime.now();
    final initialDate = state.targetDate != null
        ? DateTime(
            state.targetDate!.year,
            state.targetDate!.month,
            state.targetDate!.day,
          )
        : now.add(const Duration(days: 90));

    final picked = await AppDatePicker.show(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );

    if (picked != null && mounted) {
      ref
          .read(goalFormProvider.notifier)
          .setTargetDate(LocalDate(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(goalFormProvider.notifier);
    final strings = AppStrings.of(context);

    notifier.setName(_nameController.text);

    final rawTarget = _targetAmountController.text.trim();
    final parsedTarget = int.tryParse(rawTarget) ?? 0;
    notifier.setTargetAmount(parsedTarget);

    final rawCurrent = _currentAmountController.text.trim();
    final parsedCurrent = int.tryParse(rawCurrent) ?? 0;
    notifier.setCurrentAmount(parsedCurrent);

    notifier.setNotes(_notesController.text);

    final success = await notifier.submit();
    if (success && mounted) {
      AppFeedback.confirm(context, message: strings('goalSavedSuccess'));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final formState = ref.watch(goalFormProvider);
    final notifier = ref.read(goalFormProvider.notifier);
    final accountsAsync = ref.watch(accountsStreamProvider);

    String? errorFor(String field) {
      final key = formState.fieldErrors[field];
      return key == null ? null : strings(key);
    }

    return AppScaffold(
      title: formState.isEditMode ? strings('editGoal') : strings('newGoal'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Gem
            Center(
              child: CategoryGem(
                colorValue: formState.colorValue,
                iconKey: formState.iconKey,
                size: CategoryGemSize.xl,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Error banner
            if (formState.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.moneyOut.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: colors.moneyOut),
                ),
                child: Text(
                  formState.errorMessage!,
                  style: AppTypography.body.copyWith(color: colors.moneyOut),
                ),
              ),

            GoalBasicsSection(
              nameController: _nameController,
              targetAmountController: _targetAmountController,
              currentAmountController: _currentAmountController,
              currency: formState.currency,
              nameError: errorFor('name'),
              targetAmountError: errorFor('targetAmount'),
              currentAmountError: errorFor('currentAmount'),
            ),
            GoalDateAccountSection(
              targetDate: formState.targetDate,
              noDateLabel: strings('goalNoDate'),
              onPickDate: _pickDate,
              onClearDate: () => notifier.setTargetDate(null),
              accounts: accountsAsync,
              accountId: formState.accountId,
              onAccountChanged: notifier.setAccountId,
            ),

            // Notes
            AppTextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: strings('goalNotesLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            GoalIconColorSection(
              iconKey: formState.iconKey,
              colorValue: formState.colorValue,
              onIconChanged: notifier.setIconKey,
              onColorChanged: notifier.setColorValue,
            ),

            // Save Button
            AppButton(
              label: strings('saveGoal'),
              onPressed: formState.isSubmitting ? null : _handleSubmit,
              isLoading: formState.isSubmitting,
              isExpanded: true,
              color: colors.moneyIn,
            ),
          ],
        ),
      ),
    );
  }
}
