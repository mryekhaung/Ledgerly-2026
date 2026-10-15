import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/categories/presentation/pages/category_form_page.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_form_notifier.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:material_ui/material_ui.dart';

/// The wide layout's right-hand pane: the form, or a hint to pick something.
///
/// Extracted from `category_list_page.dart` (`docs/Conventions.md` §1).
class CategoryDetailPane extends ConsumerWidget {
  /// Creates a [CategoryDetailPane].
  const CategoryDetailPane({
    required this.editing,
    required this.onDismiss,
    super.key,
  });

  /// Whether a form is currently open.
  final bool editing;

  /// Called when the form saves, so the pane returns to its resting state.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    if (!editing) {
      return StatePlaceholder(
        icon: AppIcons.edit,
        title: strings('categoriesTitle'),
        body: strings('categoriesSelectHint'),
      );
    }

    // The pane has no route to pop, so success is handled here: the notifier's
    // `saved` flag flips once, and the pane closes in response.
    ref.listen(categoryFormProvider, (previous, next) {
      if (next.saved && (previous?.saved ?? false) == false) onDismiss();
    });

    final title = ref.watch(categoryFormProvider).isEditing
        ? strings('categoriesEdit')
        : strings('categoriesNew');

    return Container(
      color: colors.surfaceSunken,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: colors.textPrimary),
            ),
          ),
          // No `SingleChildScrollView` here: `CategoryFormBody` is already a
          // `ListView`, so it brings its own scrollable. Wrapping it in a second
          // one gives the inner viewport an unbounded box — a scroll view sizes
          // its child to the child's intrinsic height, and a `ListView` has none
          // — which throws "Vertical viewport was given unbounded height" as
          // soon as a row is tapped. `Expanded` alone gives it the pane's
          // remaining height, which is what it actually needs.
          const Expanded(child: CategoryFormBody()),
        ],
      ),
    );
  }
}
