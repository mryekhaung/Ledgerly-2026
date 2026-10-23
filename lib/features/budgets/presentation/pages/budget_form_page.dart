import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_dialog.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/presentation/providers/budget_providers.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_form/amount_section.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_form/preview_card.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_form/scope_section.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_form/threshold_section.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Page for adding or editing a budget limit.
///
/// Composition root only: sections live in `widgets/budget_form/`
/// (`docs/Conventions.md` §1).
class BudgetFormPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const BudgetFormPage({this.budgetId, this.initialType, super.key});

  /// The budget being edited, or null when creating.
  final String? budgetId;

  /// The initial scope (`total` or category).
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

    final confirmed = await AppDialog.confirm(
      context: context,
      title: strings('budgetConfirmDelete'),
      message: strings('budgetConfirmDeleteMessage'),
      confirmLabel: strings('budgetsDelete'),
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      isDestructive: true,
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
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final currency = ref.watch(currencyProvider);
    final isNew = widget.budgetId == null;
    final notifier = ref.read(budgetFormNotifierProvider.notifier);

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

    return AppScaffold(
      title: isNew ? strings('budgetsNew') : strings('budgetsEdit'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppButton(
                label: MaterialLocalizations.of(context).saveButtonLabel,
                onPressed: formState.isSaving ? null : _handleSave,
                isLoading: formState.isSaving,
                isExpanded: true,
              ),
              if (!isNew) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: formState.isSaving ? null : _handleDelete,
                  icon: Icon(
                    AppIcons.destructive,
                    size: 18,
                    color: colors.moneyOut,
                  ),
                  label: Text(
                    strings('budgetsDelete'),
                    style: AppTypography.body.copyWith(color: colors.moneyOut),
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
          BudgetScopeSection(
            isTotal: isTotal,
            categories: categories,
            selectedCategoryId:
                formState.categoryId ??
                (categories.isNotEmpty ? categories.first.id : null),
            onScopeChanged: (newIsTotal) {
              if (newIsTotal) {
                notifier.setCategory(null);
              } else {
                if (categories.isNotEmpty) {
                  notifier.setCategory(categories.first.id);
                }
              }
            },
            onCategoryChanged: notifier.setCategory,
          ),
          BudgetAmountSection(
            controller: _amountController,
            currency: currency,
            errorText: formState.fieldErrors['amount'] != null
                ? strings(formState.fieldErrors['amount']!)
                : null,
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              final exponent = currency.exponent;
              final minor = (parsed * (exponent == 0 ? 1 : 100)).round();
              notifier.setAmountMinor(minor);
            },
          ),
          BudgetThresholdSection(
            threshold: formState.alertThreshold,
            onChanged: notifier.setAlertThreshold,
          ),
          BudgetPreviewCard(
            isTotal: isTotal,
            selectedCategory: selectedCategory,
            amountMinor: formState.amountMinor,
            currency: formState.currency,
            alertThreshold: formState.alertThreshold,
          ),
        ],
      ),
    );
  }
}
