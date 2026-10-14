import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/presentation/providers/budget_providers.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Page for adding or editing a budget limit.
class BudgetFormPage extends ConsumerStatefulWidget {
  const BudgetFormPage({this.budgetId, this.initialType, super.key});

  final String? budgetId;
  final String? initialType;

  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  bool _initialized = false;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    if (widget.budgetId == null) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currency = ref.read(currencyProvider);
        final currentPeriod = ref.read(budgetPeriodProvider);
        ref
            .read(budgetFormNotifierProvider.notifier)
            .initialise(
              defaultCurrency: currency,
              currentPeriodId: currentPeriod.id,
            );
        if (widget.initialType == 'total') {
          ref.read(budgetFormNotifierProvider.notifier).setCategory(null);
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _initFromBudget(Budget budget) {
    if (_initialized) return;
    _initialized = true;

    ref.read(budgetFormNotifierProvider.notifier).initialise(budget: budget);
    final exponent = budget.currency.exponent;
    final doubleVal = budget.amountMinor / (exponent == 0 ? 1 : 100);
    _amountController.text = exponent == 0
        ? budget.amountMinor.toString()
        : doubleVal.toStringAsFixed(exponent);
  }

  Future<void> _handleSave() async {
    final strings = AppStrings.of(context);
    final success = await ref.read(budgetFormNotifierProvider.notifier).save();
    if (success && mounted) {
      AppFeedback.success();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings('budgetSavedSuccess'))));
      context.pop();
    }
  }

  Future<void> _handleDelete() async {
    final strings = AppStrings.of(context);
    final id = widget.budgetId;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings('budgetConfirmDelete')),
        content: Text(strings('budgetConfirmDeleteMessage')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.of(context).moneyOut,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings('budgetsDelete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(budgetActionNotifierProvider.notifier)
          .deleteBudget(id);
      if (success && mounted) {
        AppFeedback.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings('budgetDeletedSuccess'))),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep form notifier alive
    final formState = ref.watch(budgetFormNotifierProvider);
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final currency = ref.watch(currencyProvider);
    final isNew = widget.budgetId == null;

    final categoriesAsync = ref.watch(
      pickableCategoriesProvider(CategoryKind.expense),
    );
    final categories = categoriesAsync.value ?? const <Category>[];

    // If editing, load the budget asynchronously
    if (!isNew && !_initialized) {
      ref.watch(budgetsListStreamProvider).whenData((budgets) {
        final match = budgets.where((b) => b.id == widget.budgetId).firstOrNull;
        if (match != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initFromBudget(match);
          });
        }
      });
    }

    final isTotal = formState.isTotalBudget;
    Category? selectedCategory;
    if (!isTotal && formState.categoryId != null) {
      selectedCategory = categories
          .where((c) => c.id == formState.categoryId)
          .firstOrNull;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? strings('budgetsNew') : strings('budgetsEdit')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FilledButton(
                onPressed: formState.isSaving ? null : _handleSave,
                child: formState.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        MaterialLocalizations.of(context).saveButtonLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              if (!isNew) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: formState.isSaving ? null : _handleDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: colors.moneyOut,
                  ),
                  label: Text(
                    strings('budgetsDelete'),
                    style: TextStyle(color: colors.moneyOut),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          // Budget Scope Choice (Total vs Category)
          Text(
            strings('budgetFieldCategory'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<bool>(
            segments: <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: true,
                label: Text(strings('budgetsTotal')),
                icon: const Icon(Icons.pie_chart_outline),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text(strings('budgetsCategory')),
                icon: const Icon(Icons.category_outlined),
              ),
            ],
            selected: <bool>{isTotal},
            onSelectionChanged: (selection) {
              final newIsTotal = selection.first;
              if (newIsTotal) {
                ref.read(budgetFormNotifierProvider.notifier).setCategory(null);
              } else {
                if (categories.isNotEmpty) {
                  ref
                      .read(budgetFormNotifierProvider.notifier)
                      .setCategory(categories.first.id);
                }
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // If Category Budget, render Category Dropdown Selector
          if (!isTotal) ...<Widget>[
            DropdownButtonFormField<String>(
              initialValue:
                  formState.categoryId ??
                  (categories.isNotEmpty ? categories.first.id : null),
              decoration: InputDecoration(
                labelText: strings('budgetFieldCategory'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(budgetFormNotifierProvider.notifier)
                      .setCategory(val);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Amount Limit Field
          Text(
            strings('budgetFieldAmount'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '${currency.name.toUpperCase()} ',
              hintText: '0',
              errorText: formState.fieldErrors['amount'] != null
                  ? strings(formState.fieldErrors['amount']!)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              final exponent = currency.exponent;
              final minor = (parsed * (exponent == 0 ? 1 : 100)).round();
              ref
                  .read(budgetFormNotifierProvider.notifier)
                  .setAmountMinor(minor);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Alert Threshold Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                strings('budgetFieldThreshold'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.warningSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(formState.alertThreshold * 100).round()}%',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: formState.alertThreshold,
            min: 0.5,
            max: 1.0,
            divisions: 10,
            activeColor: colors.warning,
            onChanged: (val) {
              ref
                  .read(budgetFormNotifierProvider.notifier)
                  .setAlertThreshold(val);
            },
          ),
          Text(
            AppStrings.fill(context, 'budgetThresholdHint', <String, Object>{
              'percent': (formState.alertThreshold * 100).round(),
            }),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Live Preview Card
          Text(
            strings('categoriesPreview'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Card(
            color: colors.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.border.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (isTotal)
                        Icon(
                          Icons.pie_chart_outline,
                          color: colors.brandPrimary,
                          size: 24,
                        )
                      else if (selectedCategory != null)
                        CategoryGem(
                          colorValue: selectedCategory.colorValue,
                          iconKey: selectedCategory.iconKey,
                          size: CategoryGemSize.sm,
                        )
                      else
                        const Icon(Icons.category, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isTotal
                              ? strings('budgetsTotal')
                              : (selectedCategory?.name ??
                                    strings('budgetsCategory')),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AmountText(
                        Money.minor(formState.amountMinor, formState.currency),
                        style: AmountStyle.row,
                        signed: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: formState.alertThreshold,
                      minHeight: 8,
                      backgroundColor: colors.border.withValues(alpha: 0.35),
                      valueColor: AlwaysStoppedAnimation<Color>(colors.warning),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.fill(
                      context,
                      'budgetThresholdLive',
                      <String, Object>{
                        'percent': (formState.alertThreshold * 100).round(),
                      },
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
