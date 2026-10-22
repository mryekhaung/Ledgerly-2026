import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_date_picker.dart';
import 'package:ledgerly/core/widgets/app_dialog.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:ledgerly/features/recurring/presentation/widgets/recurring_form/details_section.dart';
import 'package:ledgerly/features/recurring/presentation/widgets/recurring_form/note_submit_section.dart';
import 'package:ledgerly/features/recurring/presentation/widgets/recurring_form/schedule_section.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:material_ui/material_ui.dart';

/// Page for creating or editing a recurring transaction rule.
///
/// Composition root only: sections live in `widgets/recurring_form/`
/// (`docs/Conventions.md` §1).
class RecurringFormPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const RecurringFormPage({this.recurringId, super.key});

  /// The rule being edited, or null when creating.
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
    final picked = await AppDatePicker.show(
      context: context,
      initialDate: initialDate.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _handleSave() async {
    final strings = AppStrings.of(context);
    final success = await ref
        .read(recurringFormNotifierProvider.notifier)
        .save();
    if (success && mounted) {
      AppFeedback.confirm(context, message: strings('recurringSavedSuccess'));
      context.pop();
    }
  }

  Future<void> _handleDelete(String ruleId) async {
    final strings = AppStrings.of(context);
    final confirm = await AppDialog.confirm(
      context: context,
      title: strings('recurringConfirmDelete'),
      message: strings('recurringConfirmDeleteMessage'),
      confirmLabel: strings('actionDelete'),
      cancelLabel: strings('actionCancel'),
      isDestructive: true,
    );
    if (confirm == true && mounted) {
      await ref
          .read(recurringSchedulerNotifierProvider.notifier)
          .delete(ruleId);
      if (mounted) {
        AppFeedback.confirm(
          context,
          message: strings('recurringDeletedSuccess'),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final formState = ref.watch(recurringFormNotifierProvider);
    final notifier = ref.read(recurringFormNotifierProvider.notifier);
    final categoryKind = formState.direction == TransactionDirection.expense
        ? CategoryKind.expense
        : CategoryKind.income;
    final categories =
        ref.watch(pickableCategoriesProvider(categoryKind)).value ??
        const <Category>[];
    final accounts =
        ref.watch(accountsStreamProvider).value ?? const <Account>[];

    final isEditing = formState.isEditing;

    return AppScaffold(
      title: isEditing ? strings('recurringEdit') : strings('recurringNew'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          RecurringDetailsSection(
            direction: formState.direction,
            amountController: _amountController,
            currency: formState.currency,
            amountError: formState.fieldErrors['amount'] != null
                ? strings(formState.fieldErrors['amount']!)
                : null,
            categories: categories,
            categoryId: formState.categoryId,
            categoryError: formState.fieldErrors['category'] != null
                ? strings(formState.fieldErrors['category']!)
                : null,
            accounts: accounts,
            accountId: formState.accountId,
            onDirectionChanged: (newDirection) {
              notifier.setDirection(newDirection);

              final newKind = newDirection == TransactionDirection.expense
                  ? CategoryKind.expense
                  : CategoryKind.income;
              final newCats =
                  ref.read(pickableCategoriesProvider(newKind)).value ??
                  const <Category>[];
              if (newCats.isNotEmpty) {
                notifier.setCategory(newCats.first.id);
              }
            },
            onAmountChanged: (val) {
              final parsed = int.tryParse(val) ?? 0;
              notifier.setAmountMinor(parsed);
            },
            onCategoryChanged: notifier.setCategory,
            onAccountChanged: notifier.setAccount,
          ),
          RecurringScheduleSection(
            frequency: formState.frequency,
            startDate: formState.startDate,
            endDate: formState.endDate,
            hasEndDate: formState.hasEndDate,
            autoAdd: formState.autoAdd,
            onFrequencyChanged: notifier.setFrequency,
            onPickStart: () => _pickDate(
              initialDate: formState.startDate,
              onPicked: notifier.setStartDate,
            ),
            onPickEnd: () => _pickDate(
              initialDate: formState.endDate ?? formState.startDate,
              onPicked: notifier.setEndDate,
            ),
            onHasEndDateChanged: (val) {
              notifier.setHasEndDate(val);
              if (val && formState.endDate == null) {
                notifier.setEndDate(formState.startDate.addMonths(12));
              }
            },
            onAutoAddChanged: notifier.setAutoAdd,
          ),
          RecurringNoteSubmitSection(
            noteController: _noteController,
            onNoteChanged: notifier.setNote,
            isSubmitting: formState.isSubmitting,
            isEditing: isEditing,
            onSubmit: _handleSave,
            onDelete: () => _handleDelete(formState.id!),
          ),
        ],
      ),
    );
  }
}
