import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:material_ui/material_ui.dart';

/// Page for creating or editing a recurring transaction rule.
class RecurringFormPage extends ConsumerStatefulWidget {
  const RecurringFormPage({this.recurringId, super.key});

  final String? recurringId;

  @override
  ConsumerState<RecurringFormPage> createState() => _RecurringFormPageState();
}

class _RecurringFormPageState extends ConsumerState<RecurringFormPage> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initForm());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _initForm() async {
    final notifier = ref.read(recurringFormNotifierProvider.notifier);
    if (widget.recurringId != null) {
      final getUseCase = ref.read(getRecurringTransactionUseCaseProvider);
      final item = await getUseCase(widget.recurringId!);
      if (item != null && mounted) {
        notifier.initForEdit(item);
        _amountController.text = '${item.amountMinor}';
        _noteController.text = item.note ?? '';
      }
    } else {
      final categories =
          ref.read(pickableCategoriesProvider(CategoryKind.expense)).value ??
          const <Category>[];
      final firstCat = categories.firstOrNull;
      notifier.initForCreate(categoryId: firstCat?.id);
    }
  }

  Future<void> _pickDate({
    required LocalDate initialDate,
    required ValueChanged<LocalDate> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(LocalDate.fromDateTime(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    final formState = ref.watch(recurringFormNotifierProvider);
    final categoryKind = formState.direction == TransactionDirection.expense
        ? CategoryKind.expense
        : CategoryKind.income;
    final categories =
        ref.watch(pickableCategoriesProvider(categoryKind)).value ??
        const <Category>[];
    final accounts =
        ref.watch(accountsStreamProvider).value ?? const <Account>[];

    final isEditing = formState.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? strings('recurringEdit') : strings('recurringNew'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          // Direction selector (Expense / Income)
          SegmentedButton<TransactionDirection>(
            segments: <ButtonSegment<TransactionDirection>>[
              ButtonSegment<TransactionDirection>(
                value: TransactionDirection.expense,
                label: Text(strings('transactionDirectionExpense')),
                icon: const Icon(Icons.arrow_upward, size: 16),
              ),
              ButtonSegment<TransactionDirection>(
                value: TransactionDirection.income,
                label: Text(strings('transactionDirectionIncome')),
                icon: const Icon(Icons.arrow_downward, size: 16),
              ),
            ],
            selected: {formState.direction},
            onSelectionChanged: (selection) {
              final newDirection = selection.first;
              ref
                  .read(recurringFormNotifierProvider.notifier)
                  .setDirection(newDirection);

              final newKind = newDirection == TransactionDirection.expense
                  ? CategoryKind.expense
                  : CategoryKind.income;
              final newCats =
                  ref.read(pickableCategoriesProvider(newKind)).value ??
                  const <Category>[];
              if (newCats.isNotEmpty) {
                ref
                    .read(recurringFormNotifierProvider.notifier)
                    .setCategory(newCats.first.id);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: strings('budgetFieldAmount'),
              prefixText: '${formState.currency.code.toUpperCase()} ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: formState.fieldErrors['amount'] != null
                  ? strings(formState.fieldErrors['amount']!)
                  : null,
            ),
            onChanged: (val) {
              final parsed = int.tryParse(val) ?? 0;
              ref
                  .read(recurringFormNotifierProvider.notifier)
                  .setAmountMinor(parsed);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Category dropdown
          DropdownButtonFormField<String>(
            initialValue: formState.categoryId.isNotEmpty
                ? formState.categoryId
                : (categories.isNotEmpty ? categories.first.id : null),
            decoration: InputDecoration(
              labelText: strings('budgetFieldCategory'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: formState.fieldErrors['category'] != null
                  ? strings(formState.fieldErrors['category']!)
                  : null,
            ),
            items: categories.map((cat) {
              return DropdownMenuItem<String>(
                value: cat.id,
                child: Row(
                  children: <Widget>[
                    CategoryGem(
                      colorValue: cat.colorValue,
                      iconKey: cat.iconKey,
                      size: CategoryGemSize.sm,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(cat.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (catId) {
              if (catId != null) {
                ref
                    .read(recurringFormNotifierProvider.notifier)
                    .setCategory(catId);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Account selector (optional)
          if (accounts.isNotEmpty) ...<Widget>[
            DropdownButtonFormField<String?>(
              initialValue: formState.accountId,
              decoration: InputDecoration(
                labelText: 'Account (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No Account specified'),
                ),
                ...accounts.map(
                  (acc) => DropdownMenuItem<String?>(
                    value: acc.id,
                    child: Text('${acc.name} (${acc.currency.code})'),
                  ),
                ),
              ],
              onChanged: (accId) {
                ref
                    .read(recurringFormNotifierProvider.notifier)
                    .setAccount(accId);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Frequency dropdown
          DropdownButtonFormField<RecurringFrequency>(
            initialValue: formState.frequency,
            decoration: InputDecoration(
              labelText: strings('recurringFieldFrequency'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: RecurringFrequency.values.map((freq) {
              final label = switch (freq) {
                RecurringFrequency.daily => strings('recurringFrequencyDaily'),
                RecurringFrequency.weekly => strings(
                  'recurringFrequencyWeekly',
                ),
                RecurringFrequency.monthly => strings(
                  'recurringFrequencyMonthly',
                ),
                RecurringFrequency.yearly => strings(
                  'recurringFrequencyYearly',
                ),
              };
              return DropdownMenuItem<RecurringFrequency>(
                value: freq,
                child: Text(label),
              );
            }).toList(),
            onChanged: (freq) {
              if (freq != null) {
                ref
                    .read(recurringFormNotifierProvider.notifier)
                    .setFrequency(freq);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Start Date row
          ListTile(
            tileColor: colors.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
            ),
            leading: Icon(Icons.calendar_today, color: colors.brandPrimary),
            title: Text(strings('recurringFieldStartDate')),
            subtitle: Text('${formState.startDate}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _pickDate(
              initialDate: formState.startDate,
              onPicked: (d) => ref
                  .read(recurringFormNotifierProvider.notifier)
                  .setStartDate(d),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Has end date switch
          SwitchListTile(
            title: Text(strings('recurringFieldHasEndDate')),
            value: formState.hasEndDate,
            onChanged: (val) {
              ref
                  .read(recurringFormNotifierProvider.notifier)
                  .setHasEndDate(val);
              if (val && formState.endDate == null) {
                ref
                    .read(recurringFormNotifierProvider.notifier)
                    .setEndDate(formState.startDate.addMonths(12));
              }
            },
          ),

          if (formState.hasEndDate && formState.endDate != null) ...<Widget>[
            ListTile(
              tileColor: colors.surfaceRaised,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
              ),
              leading: Icon(Icons.event, color: colors.moneyOut),
              title: Text(strings('recurringFieldEndDate')),
              subtitle: Text('${formState.endDate}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _pickDate(
                initialDate: formState.endDate!,
                onPicked: (d) => ref
                    .read(recurringFormNotifierProvider.notifier)
                    .setEndDate(d),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Auto-add switch
          SwitchListTile(
            title: Text(strings('recurringFieldAutoAdd')),
            subtitle: Text(
              strings('recurringFieldAutoAddDesc'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            value: formState.autoAdd,
            onChanged: (val) {
              ref.read(recurringFormNotifierProvider.notifier).setAutoAdd(val);
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Note input
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: strings('transactionNoteLabel'),
              hintText: strings('transactionNoteHint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) {
              ref.read(recurringFormNotifierProvider.notifier).setNote(val);
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Submit button
          FilledButton(
            onPressed: formState.isSubmitting
                ? null
                : () async {
                    final success = await ref
                        .read(recurringFormNotifierProvider.notifier)
                        .save();
                    if (success && context.mounted) {
                      AppFeedback.confirm(
                        context,
                        message: strings('recurringSavedSuccess'),
                      );
                      context.pop();
                    }
                  },
            child: formState.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(strings('transactionSave')),
          ),

          if (isEditing) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.moneyOut,
                side: BorderSide(color: colors.moneyOut),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(strings('recurringConfirmDelete')),
                    content: Text(strings('recurringConfirmDeleteMessage')),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(strings('actionCancel')),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(strings('actionDelete')),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref
                      .read(recurringSchedulerNotifierProvider.notifier)
                      .delete(formState.id!);
                  if (context.mounted) {
                    AppFeedback.confirm(
                      context,
                      message: strings('recurringDeletedSuccess'),
                    );
                    context.pop();
                  }
                }
              },
              child: Text(strings('recurringActionDelete')),
            ),
          ],
        ],
      ),
    );
  }
}
