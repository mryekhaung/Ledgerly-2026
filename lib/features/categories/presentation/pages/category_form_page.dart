import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/category_catalog.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_form_notifier.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:material_ui/material_ui.dart';

/// The category create/edit form.
///
/// One page for both modes, driven entirely by [categoryFormProvider]: the only
/// difference between creating and editing is whether the notifier was seeded
/// with an existing category, so a second near-identical page would be two
/// places to fix every future change.
///
/// Validation lives in `CategoryValidators` (domain) and arrives here as
/// `ValidationFailure.fieldErrors`; the page resolves those keys to text and
/// marks the offending field, never deciding for itself what is invalid
/// (`docs/Agent.md` §3.1).
///
/// On expanded windows the same body is rendered *inside* the list page as the
/// detail pane (see [CategoryFormBody]) rather than as a route, so the list stays
/// visible while editing (docs/Platform.md §5). This page is the compact/medium
/// presentation of it.
class CategoryFormPage extends ConsumerWidget {
  /// Creates the form page.
  const CategoryFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final state = ref.watch(categoryFormProvider);

    // Popping on success is a side effect, so it is observed rather than done
    // inside `build` (`docs/Architecture.md` §5). The wide layout does not pop —
    // there is no route to pop — so the body reports success through its own
    // callback there instead.
    ref.listen(categoryFormProvider, (previous, next) {
      if (next.saved && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    return ModalFormScaffold(
      title: state.isEditing
          ? strings('categoriesEdit')
          : strings('categoriesNew'),
      child: const CategoryFormBody(),
    );
  }
}

/// The form's fields, independent of the chrome around them.
///
/// Split out so the two presentations cannot drift: the compact route wraps it in
/// a [ModalFormScaffold], the wide layout drops it into the detail pane, and the
/// fields — the part with the actual behaviour — exist once.
class CategoryFormBody extends ConsumerWidget {
  /// Creates the form body.
  const CategoryFormBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final state = ref.watch(categoryFormProvider);
    final notifier = ref.read(categoryFormProvider.notifier);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          _FieldLabel(label: strings('categoriesNameLabel')),
          const SizedBox(height: AppSpacing.sm),
          _NameField(
            initialValue: state.name,
            hintText: strings('categoriesNameHint'),
            errorText: _errorFor(state, 'name', strings),
            autofocus: !state.isEditing,
            onChanged: notifier.setName,
          ),

          const SizedBox(height: AppSpacing.xl),
          _FieldLabel(label: strings('categoriesKindLabel')),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<CategoryKind>(
            segments: <ButtonSegment<CategoryKind>>[
              ButtonSegment<CategoryKind>(
                value: CategoryKind.expense,
                label: Text(strings('transactionDirectionExpense')),
                icon: const Icon(Icons.arrow_upward),
              ),
              ButtonSegment<CategoryKind>(
                value: CategoryKind.income,
                label: Text(strings('transactionDirectionIncome')),
                icon: const Icon(Icons.arrow_downward),
              ),
            ],
            selected: <CategoryKind>{state.kind},
            onSelectionChanged: (selection) =>
                notifier.setKind(selection.first),
          ),

          const SizedBox(height: AppSpacing.xl),
          _FieldLabel(label: strings('categoriesPreview')),
          const SizedBox(height: AppSpacing.sm),
          _PreviewCard(state: state),
          if (_errorFor(state, 'iconKey', strings)
              case final error?) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _FieldError(message: error),
          ],

          const SizedBox(height: AppSpacing.xl),
          _FieldLabel(label: strings('categoriesIconLabel')),
          const SizedBox(height: AppSpacing.sm),
          _IconGrid(selectedKey: state.iconKey, onSelected: notifier.setIcon),

          const SizedBox(height: AppSpacing.xl),
          _FieldLabel(label: strings('categoriesColorLabel')),
          const SizedBox(height: AppSpacing.sm),
          _ColorPalette(
            selectedValue: state.colorValue,
            onSelected: notifier.setColor,
          ),

          if (state.failure case final failure?
              when state.fieldErrors.isEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            _FieldError(
              message: strings(
                AppLocalization.failureKeyFor(failure.runtimeType.toString()),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: state.isSaving ? null : notifier.save,
            child: state.isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : Text(strings('actionSave')),
          ),
        ],
      ),
    );
  }

  /// Resolves a field's validation message, or null when the field is clean.
  static String? _errorFor(
    CategoryFormState state,
    String field,
    String Function(String key) strings,
  ) {
    final key = state.fieldErrors[field];
    return key == null ? null : strings(AppLocalization.validationKeyFor(key));
  }
}

/// The name field, owning its own [TextEditingController].
///
/// A `StatefulWidget` rather than a controller built inline in `build`: creating
/// one per rebuild would reset the cursor on every keystroke, and caching them
/// in a static map would leak one per page visit. This keeps the controller's
/// lifetime exactly the field's.
class _NameField extends StatefulWidget {
  const _NameField({
    required this.initialValue,
    required this.hintText,
    required this.errorText,
    required this.autofocus,
    required this.onChanged,
  });

  final String initialValue;
  final String hintText;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    autofocus: widget.autofocus,
    textInputAction: TextInputAction.done,
    maxLength: 60,
    onChanged: widget.onChanged,
    decoration: InputDecoration(
      hintText: widget.hintText,
      errorText: widget.errorText,
      counterText: '',
    ),
  );
}

/// A small label above a form section.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppThemeColors.of(context).textTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// An inline validation message.
class _FieldError extends StatelessWidget {
  const _FieldError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}

/// Shows what the category will look like in a list, as the user edits it.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.state});

  final CategoryFormState state;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    // Falls back to the hint so an empty name still renders a plausible row
    // rather than a blank gem with nothing beside it.
    final name = state.name.trim().isEmpty ? '—' : state.name.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: AppRadius.borderLg,
      ),
      child: CategoryGemLabel(
        name: name,
        colorValue: state.colorValue,
        iconKey: state.iconKey,
        size: CategoryGemSize.lg,
        subtitle: state.kind == CategoryKind.income ? 'Income' : 'Expense',
      ),
    );
  }
}

/// The scrollable icon grid.
class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.selectedKey, required this.onSelected});

  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final key in CategoryIcons.keys)
          _SelectableCell(
            isSelected: key == selectedKey,
            onTap: () => onSelected(key),
            child: Icon(
              CategoryIcons.iconFor(key),
              size: 20,
              color: key == selectedKey
                  ? colors.textOnBrand
                  : colors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// The colour swatches.
class _ColorPalette extends StatelessWidget {
  const _ColorPalette({required this.selectedValue, required this.onSelected});

  final int selectedValue;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final value in CategoryPalette.colors)
          _SelectableCell(
            isSelected: value == selectedValue,
            onTap: () => onSelected(value),
            // A ring rather than a checkmark: the swatch's own colour is the
            // content, so overlaying a glyph would hide what is being chosen.
            ringColor: colors.textPrimary,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(value),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

/// A tappable square that shows selected state.
///
/// Shared by the icon grid and the colour palette so both are the same hit
/// target size and the same focus/selection affordance
/// (`docs/Platform.md` — 44pt minimum touch target).
class _SelectableCell extends StatelessWidget {
  const _SelectableCell({
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.ringColor,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderFull,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? colors.brandPrimary : colors.surfaceRaised,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? (ringColor ?? colors.brandPrimary)
                : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
