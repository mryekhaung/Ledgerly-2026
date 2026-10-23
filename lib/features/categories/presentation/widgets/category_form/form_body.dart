import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_form_notifier.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_form/color_picker.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_form/field_error.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_form/field_label.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_form/icon_grid.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_form/name_field.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_form/preview_card.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:material_ui/material_ui.dart';

/// The form's fields, independent of the chrome around them.
///
/// Split out so the two presentations cannot drift: the compact route wraps it in
/// a modal form scaffold, the wide layout drops it into the detail pane, and the
/// fields — the part with the actual behaviour — exist once.
///
/// Extracted from `category_form_page.dart` (`docs/Conventions.md` §1).
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
          FieldLabel(label: strings('categoriesNameLabel')),
          const SizedBox(height: AppSpacing.sm),
          NameField(
            initialValue: state.name,
            hintText: strings('categoriesNameHint'),
            errorText: _errorFor(state, 'name', strings),
            autofocus: !state.isEditing,
            onChanged: notifier.setName,
          ),

          const SizedBox(height: AppSpacing.xl),
          FieldLabel(label: strings('categoriesKindLabel')),
          const SizedBox(height: AppSpacing.sm),
          SegmentedTabs<CategoryKind>(
            tabs: <SegmentedTab<CategoryKind>>[
              SegmentedTab<CategoryKind>(
                value: CategoryKind.expense,
                label: strings('transactionDirectionExpense'),
                icon: AppIcons.increase,
              ),
              SegmentedTab<CategoryKind>(
                value: CategoryKind.income,
                label: strings('transactionDirectionIncome'),
                icon: AppIcons.decrease,
              ),
            ],
            selected: state.kind,
            onChanged: notifier.setKind,
          ),

          const SizedBox(height: AppSpacing.xl),
          FieldLabel(label: strings('categoriesPreview')),
          const SizedBox(height: AppSpacing.sm),
          CategoryPreviewCard(state: state),
          if (_errorFor(state, 'iconKey', strings)
              case final error?) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            FieldError(message: error),
          ],

          const SizedBox(height: AppSpacing.xl),
          FieldLabel(label: strings('categoriesIconLabel')),
          const SizedBox(height: AppSpacing.sm),
          IconGrid(selectedKey: state.iconKey, onSelected: notifier.setIcon),

          const SizedBox(height: AppSpacing.xl),
          FieldLabel(label: strings('categoriesColorLabel')),
          const SizedBox(height: AppSpacing.sm),
          CategoryColorPicker(
            selectedValue: state.colorValue,
            onSelected: notifier.setColor,
          ),

          if (state.failure case final failure?
              when state.fieldErrors.isEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            FieldError(
              message: strings(
                AppLocalization.failureKeyFor(failure.runtimeType.toString()),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            onPressed: state.isSaving ? null : notifier.save,
            label: strings('actionSave'),
            isLoading: state.isSaving,
            isExpanded: true,
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
