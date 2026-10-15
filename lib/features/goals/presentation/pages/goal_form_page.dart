import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/goals/presentation/providers/goals_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

const List<int> _kGoalColors = [
  0xFF2E7D32, // Emerald
  0xFF1976D2, // Blue
  0xFF7B1FA2, // Purple
  0xFF00796B, // Teal
  0xFFE65100, // Orange
  0xFFC2185B, // Pink
  0xFF303F9F, // Indigo
  0xFFF57F17, // Amber
];

const List<String> _kGoalIcons = [
  'savings',
  'laptop',
  'flight',
  'directions_car',
  'home',
  'school',
  'shopping_bag',
  'favorite',
];

/// Page for creating or editing a savings goal.
class GoalFormPage extends ConsumerStatefulWidget {
  const GoalFormPage({this.goalId, super.key});

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

    final picked = await showDatePicker(
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
    final accountsAsync = ref.watch(accountsStreamProvider);

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

            // Goal Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: strings('goalNameLabel'),
                border: const OutlineInputBorder(),
                errorText: formState.fieldErrors['name'] != null
                    ? strings(formState.fieldErrors['name']!)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Target Amount
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings('goalTargetAmountLabel'),
                prefixText: '${formState.currency.name.toUpperCase()} ',
                border: const OutlineInputBorder(),
                errorText: formState.fieldErrors['targetAmount'] != null
                    ? strings(formState.fieldErrors['targetAmount']!)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Current Saved Amount
            TextField(
              controller: _currentAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings('goalCurrentAmountLabel'),
                prefixText: '${formState.currency.name.toUpperCase()} ',
                border: const OutlineInputBorder(),
                errorText: formState.fieldErrors['currentAmount'] != null
                    ? strings(formState.fieldErrors['currentAmount']!)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Target Date picker tile
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderSm,
                side: BorderSide(color: colors.border),
              ),
              title: Text(strings('goalTargetDateLabel')),
              subtitle: Text(
                // §7: dates render via intl for the active locale, never as a
                // hand-built ISO fragment.
                formState.targetDate != null
                    ? DateFormat.yMd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).format(formState.targetDate!.toDateTime())
                    : strings('goalNoDate'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (formState.targetDate != null)
                    IconButton(
                      icon: const Icon(AppIcons.close, size: 20),
                      onPressed: () => ref
                          .read(goalFormProvider.notifier)
                          .setTargetDate(null),
                    ),
                  const Icon(AppIcons.calendar),
                ],
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.md),

            // Account selection
            accountsAsync.when(
              data: (accounts) => DropdownButtonFormField<String?>(
                initialValue: formState.accountId,
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
                onChanged: (val) =>
                    ref.read(goalFormProvider.notifier).setAccountId(val),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: strings('goalNotesLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Icon Picker
            Text(
              strings('goalIconLabel'),
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final iconKey in _kGoalIcons)
                  GestureDetector(
                    onTap: () =>
                        ref.read(goalFormProvider.notifier).setIconKey(iconKey),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: formState.iconKey == iconKey
                            ? colors.moneyIn.withValues(alpha: 0.2)
                            : colors.surfaceRaised,
                        border: Border.all(
                          color: formState.iconKey == iconKey
                              ? colors.moneyIn
                              : colors.border,
                          width: formState.iconKey == iconKey ? 2 : 1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CategoryGem(
                        colorValue: formState.colorValue,
                        iconKey: iconKey,
                        size: CategoryGemSize.md,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Color Picker
            Text(
              strings('goalColorLabel'),
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final colorVal in _kGoalColors)
                  GestureDetector(
                    onTap: () => ref
                        .read(goalFormProvider.notifier)
                        .setColorValue(colorVal),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        // Selection is the 3 px ring alone: §4.3 allows only
                        // flat/raised/floating elevation, not a bespoke glow.
                        border: formState.colorValue == colorVal
                            ? Border.all(color: colors.textOnBrand, width: 3)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save Button
            FilledButton(
              onPressed: formState.isSubmitting ? null : _handleSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.moneyIn,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              child: formState.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      strings('saveGoal'),
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
