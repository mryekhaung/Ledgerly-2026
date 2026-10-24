import 'dart:async';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveAppBarAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_form_notifier.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_form/form_body.dart';
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
///
/// Composition root only: the body lives in `widgets/category_form/`
/// (`docs/Conventions.md` §1).
class CategoryFormPage extends ConsumerWidget {
  /// Creates the form page.
  const CategoryFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final state = ref.watch(categoryFormProvider);
    final notifier = ref.read(categoryFormProvider.notifier);

    // Popping on success is a side effect, so it is observed rather than done
    // inside `build` (`docs/Architecture.md` §5). The wide layout does not pop —
    // there is no route to pop — so the body reports success through its own
    // callback there instead.
    ref.listen(categoryFormProvider, (previous, next) {
      if (next.saved && context.canPop()) {
        context.pop();
      }
    });

    return AppScaffold(
      title: state.isEditing
          ? strings('categoriesEdit')
          : strings('categoriesNew'),
      adaptiveActions: <AdaptiveAppBarAction>[
        AdaptiveAppBarAction(
          title: strings('actionSave'),
          label: strings('actionSave'),
          tintColor: colors.brandPrimary,
          onPressed: () {
            if (!state.isSaving) unawaited(notifier.save());
          },
        ),
      ],
      body: const CategoryFormBody(),
    );
  }
}
