import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/amount_keypad.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/core/widgets/form_field_surface.dart';
import 'package:ledgerly/core/widgets/month_day_picker_page.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/presentation/pages/category_picker_page.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_form_notifier.dart';
import 'package:ledgerly/features/transactions/presentation/transaction_form_state.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:material_ui/material_ui.dart';

/// The add/edit transaction page.
///
/// One page for both modes: the only difference is whether the notifier was
/// seeded with an existing transaction.
///
/// The layout is the keypad with the editable fields **above** it, so the
/// numbers sit at thumb height on a phone and the tray never covers what is
/// being edited (`docs/Design.md` §5.8 — the numeric keypad is a dedicated tray,
/// never the OS keyboard).
///
/// The category row doubles as the keypad's header: it shows the chosen
/// category's gem and name, which is exactly the context the user needs while
/// typing a number, so it is not repeated twice on screen.
class TransactionFormPage extends ConsumerStatefulWidget {
  /// Creates the form.
  const TransactionFormPage({this.existing, this.initialDate, super.key});

  /// The transaction being edited, or null when creating.
  final Transaction? existing;

  /// The day a new transaction should default to — the calendar's selected day.
  final LocalDate? initialDate;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  /// The note's controller, owned here so it is disposed with the page — a
  /// controller created in `build` resets the cursor on every keystroke, and one
  /// cached in a static map leaks a controller per page visit.
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.existing?.note ?? '');
    // Seeded after the first frame so the notifier already exists and the
    // provider is not written to during `build`
    // (`docs/Architecture.md` §5).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(transactionFormProvider.notifier)
          .initialise(
            existing: widget.existing,
            initialDate: widget.initialDate,
          );
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = ref.watch(transactionFormProvider);
    final notifier = ref.read(transactionFormProvider.notifier);

    // Popping on success is a side effect, so it is observed rather than done
    // inside `build`.
    ref.listen(transactionFormProvider, (previous, next) {
      if (next.saved && !(previous?.saved ?? false)) {
        // The confirmation and the tap both belong to a *transition* into saved,
        // not to every rebuild while saved is true — otherwise a re-layout would
        // buzz again.
        AppFeedback.success();
        AppFeedback.confirm(context, message: strings('transactionSaved'));
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      }
    });

    // Switching direction changes which categories are legal, so a category
    // picked for the other direction is dropped rather than silently saved onto
    // a transaction it does not belong to.
    final category = _selectedCategory(state);

    return AppScaffold(
      title: state.isEditing
          ? strings('transactionEdit')
          : strings('transactionNew'),
      actions: <Widget>[
        TextButton(
          onPressed: state.isSaving ? null : notifier.save,
          child: state.isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : Text(strings('transactionSave')),
        ),
      ],
      useSafeArea: false,
      body: SafeArea(
        bottom: false,
        // On medium and up the form becomes a centred column rather than a
        // full-bleed page (docs/Platform.md §5): the keypad is a fixed-width
        // tray, and letting it stretch across a desktop window would put the
        // digits a hand-width apart from the amount being typed.
        child: ConstrainedPane(
          maxWidth: AppSpacing.proseMaxWidth,
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    _DirectionToggle(
                      direction: state.direction,
                      onChanged: notifier.setDirection,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FieldGroup(
                      label: strings('transactionCategoryLabel'),
                      error: _errorFor(state, 'categoryId', strings),
                      field: FormFieldSurface(
                        label: strings('transactionCategoryLabel'),
                        value: category?.name,
                        leading: category == null
                            ? null
                            : CategoryGem(
                                colorValue: category.colorValue,
                                iconKey: category.iconKey,
                                size: CategoryGemSize.md,
                              ),
                        trailing: const FormFieldChevron(),
                        isError: state.fieldErrors.containsKey('categoryId'),
                        onTap: () => _pickCategory(state.direction),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FieldGroup(
                      label: strings('transactionDateLabel'),
                      field: FormFieldSurface(
                        label: strings('transactionDateLabel'),
                        value: _formatDate(context, state.date),
                        trailing: const FormFieldChevron(),
                        onTap: () => _pickDate(state.date),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FieldGroup(
                      label: strings('transactionNoteLabel'),
                      error: _errorFor(state, 'note', strings),
                      field: _NoteField(
                        controller: _noteController,
                        hint: strings('transactionNoteHint'),
                        onChanged: notifier.setNote,
                      ),
                    ),
                    if (_generalError(state, strings) case final message?)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: FormFieldError(message: message),
                      ),
                  ],
                ),
              ),
              AmountKeypad(
                entryBuffer: state.entryBuffer,
                currency: state.currency,
                semanticsLabel: strings('transactionAmountLabel'),
                onDigit: notifier.enterDigit,
                onDecimalPoint: notifier.enterDecimalPoint,
                onBackspace: notifier.backspace,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resolves the chosen category from the pickable list for the current
  /// direction, or null when nothing is chosen.
  ///
  /// Read from the same stream the picker uses, so the row and the picker can
  /// never disagree about a category's name or colour. Reading `.value` from the
  /// derived [pickableCategoriesProvider] is the right call here: the row renders
  /// from whatever the stream has emitted so far, and a failure simply leaves the
  /// row showing its placeholder rather than blocking the form.
  Category? _selectedCategory(TransactionFormState state) {
    final id = state.categoryId;
    if (id == null) return null;

    final categories = ref
        .watch(pickableCategoriesProvider(_kindFor(state.direction)))
        .value;
    if (categories == null) return null;

    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Opens the category picker and stores the choice.
  Future<void> _pickCategory(TransactionDirection direction) async {
    final chosen = await Navigator.of(context).push<Category>(
      MaterialPageRoute<Category>(
        builder: (_) => CategoryPickerPage(
          kind: _kindFor(direction),
          selectedId: ref.read(transactionFormProvider).categoryId,
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    ref.read(transactionFormProvider.notifier).setCategory(chosen.id);
  }

  /// Opens the day picker and stores the choice.
  Future<void> _pickDate(LocalDate current) async {
    final chosen = await Navigator.of(context).push<LocalDate>(
      MaterialPageRoute<LocalDate>(
        builder: (_) => MonthDayPickerPage(initialDate: current),
      ),
    );
    if (chosen == null || !mounted) return;
    ref.read(transactionFormProvider.notifier).setDate(chosen);
  }

  /// Resolves a field's validation message, or null when clean.
  static String? _errorFor(
    TransactionFormState state,
    String field,
    String Function(String key) strings,
  ) {
    final key = state.fieldErrors[field];
    return key == null ? null : strings(AppLocalization.validationKeyFor(key));
  }

  /// Resolves the non-field failure message, or null when there is none.
  ///
  /// A `ValidationFailure` is already rendered against its field, so it is not
  /// repeated as a banner; anything else has no field to attach to.
  static String? _generalError(
    TransactionFormState state,
    String Function(String key) strings,
  ) {
    final failure = state.failure;
    if (failure == null || failure is ValidationFailure) return null;
    return strings(
      AppLocalization.failureKeyFor(failure.runtimeType.toString()),
    );
  }

  /// Maps a transaction direction onto the category kind it may use.
  static CategoryKind _kindFor(TransactionDirection direction) =>
      direction == TransactionDirection.income
      ? CategoryKind.income
      : CategoryKind.expense;

  /// Formats a day for display using the platform's locale data.
  ///
  /// `yMMMMd` comes from CLDR, so the day is written the way the locale writes
  /// days — no ARB key per locale, and no fixed `dd/MM/yyyy` that is wrong for
  /// half the world. The month grid and this row therefore agree.
  static String _formatDate(BuildContext context, LocalDate date) =>
      MaterialLocalizations.of(context)
          .formatMediumDate(date.toUtcDateTime().toLocal());
}

/// The expense/income switch.
class _DirectionToggle extends StatelessWidget {
  const _DirectionToggle({required this.direction, required this.onChanged});

  final TransactionDirection direction;
  final ValueChanged<TransactionDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SegmentedTabs<TransactionDirection>(
      tabs: <SegmentedTab<TransactionDirection>>[
        SegmentedTab<TransactionDirection>(
          value: TransactionDirection.expense,
          label: strings('transactionDirectionExpense'),
          icon: AppIcons.increase,
        ),
        SegmentedTab<TransactionDirection>(
          value: TransactionDirection.income,
          label: strings('transactionDirectionIncome'),
          icon: AppIcons.decrease,
        ),
      ],
      selected: direction,
      onChanged: onChanged,
    );
  }
}

/// A labelled field plus its inline error.
class _FieldGroup extends StatelessWidget {
  const _FieldGroup({required this.label, required this.field, this.error});

  final String label;
  final Widget field;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      field,
      if (error case final message?) FormFieldError(message: message),
    ],
  );
}

/// The free-text note field.
///
/// Owns its own [TextEditingController] rather than receiving one, so the
/// controller's lifetime is exactly the widget's — see the note on
/// [_TransactionFormPageState] for why that matters.
class _NoteField extends StatefulWidget {
  const _NoteField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        maxLines: 2,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        style: theme.textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
        cursorColor: colors.brandPrimary,
        // `border: InputBorder.none` is the point of this widget: the fill and
        // radius come from the container above, per `docs/Design.md` §5.8, which
        // forbids outline boxes.
        decoration: InputDecoration.collapsed(
          hintText: widget.hint,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ),
    );
  }
}
