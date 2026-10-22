import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_form_notifier.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_list_notifier.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_list/detail_pane.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_list/list_body.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:material_ui/material_ui.dart';

/// The categories list: every active category, then the archived ones.
///
/// Compact/medium: one scrolling column, and edit opens the form as a route.
/// Expanded and up: **master–detail** — the list on the left, the form on the
/// right, so switching between categories is a tap rather than a
/// push-and-pop cycle (docs/Platform.md §5).
///
/// Reads its state from [categoryListProvider] and mutates through the category
/// use cases — the page itself holds no list state, so a change made anywhere
/// else in the app repaints it (`docs/Architecture.md` §5).
///
/// Composition root only: body, pane and rows live in `widgets/category_list/`
/// (`docs/Conventions.md` §1).
class CategoryListPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const CategoryListPage({super.key});

  @override
  ConsumerState<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends ConsumerState<CategoryListPage> {
  /// The category shown in the wide layout's detail pane, or null for "new".
  ///
  /// Only meaningful on expanded windows, where the form is a pane instead of a
  /// route. Null on the first build means the pane shows the create form, which
  /// is the useful default: an empty detail pane would be a large dead area.
  Category? _paneCategory;

  /// Whether the wide detail pane is showing a form at all.
  ///
  /// Separate from `[_paneCategory] == null` on purpose: "creating a new one" and
  /// "nothing selected yet" both have a null category, and the pane must be able
  /// to tell them apart to decide between the form and a placeholder.
  bool _paneEditing = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = ref.watch(categoryListProvider);
    final sizeClass = WindowSizeClass.of(context);

    // Keep the pane's form draft alive for as long as this page is mounted.
    //
    // `categoryFormProvider` is `autoDispose` (a half-typed draft must not leak
    // out of the form), and on the wide layout the pane is its only listener —
    // but the pane only starts listening once `_paneEditing` flips true.
    // `_openForm` seeds the draft *before* that, on purpose: the pane's very
    // first build must already show the tapped category. With no listener at
    // that instant the provider is disposed the moment `ref.read` returns, so
    // the seed is dropped and the pane comes up as a blank "New category" form —
    // the wrong category, silently. Subscribing here, on the page that owns the
    // pane, pins the provider for the page's lifetime without requesting a
    // rebuild of this widget.
    ref.listen(categoryFormProvider, (previous, next) {});

    final body = switch (state) {
      AsyncData(:final value) => CategoryListBody(
        state: value,
        onEdit: (category) => _openForm(existing: category),
        onDelete: _delete,
        onToggleArchive: _toggleArchive,
        selectedId: _paneEditing ? _paneCategory?.id : null,
      ),
      AsyncError() => StatePlaceholder(
        icon: AppIcons.error,
        title: strings('stateErrorTitle'),
        body: strings('stateErrorBody'),
        action: FilledButton(
          onPressed: () => ref.invalidate(categoryListProvider),
          child: Text(strings('stateErrorRetry')),
        ),
      ),
      _ => const LoadingPlaceholder(),
    };

    // The split is a presentation change only: the same list and the same form,
    // arranged differently.
    if (sizeClass.usesSidebar) {
      return AppScaffold(
        title: strings('categoriesTitle'),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openForm,
          icon: const Icon(AppIcons.add),
          label: Text(strings('categoriesNew')),
        ),
        body: Row(
          // `stretch`, not `start`: the detail pane hosts `CategoryFormBody`,
          // which is a `ListView`. `start` sizes each child to its intrinsic
          // height, so the moment a row is tapped and the form appears the
          // viewport is handed an unbounded box and throws "Vertical viewport
          // was given unbounded height". `stretch` gives both panes the row's
          // full height, which is also what lets the list and the form scroll
          // independently.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(flex: 4, child: body),
            VerticalDivider(width: 1, color: AppThemeColors.of(context).border),
            Expanded(
              flex: 6,
              child: CategoryDetailPane(
                editing: _paneEditing,
                onDismiss: _closePane,
              ),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      title: strings('categoriesTitle'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(AppIcons.add),
        label: Text(strings('categoriesNew')),
      ),
      body: body,
    );
  }

  /// Opens the create/edit form.
  ///
  /// Wide windows get the form in the detail pane; narrower ones push the route.
  /// Seeding happens through the form notifier either way, so the form has
  /// exactly one entry point for "new" and "edit".
  void _openForm({Category? existing}) {
    ref.read(categoryFormProvider.notifier).initialise(existing: existing);

    if (WindowSizeClass.of(context).usesSidebar) {
      setState(() {
        _paneCategory = existing;
        _paneEditing = true;
      });
      return;
    }

    unawaited(context.pushNamed(AppRoutes.categoryEditName));
  }

  /// Hides the wide layout's detail pane.
  void _closePane() {
    setState(() {
      _paneCategory = null;
      _paneEditing = false;
    });
  }

  /// Soft-deletes after an explicit confirmation.
  ///
  /// Confirmed because deletion is the one irreversible-looking action here;
  /// archiving exists for the reversible case and is offered in the same menu.
  ///
  /// The confirmation is still worth having even though the delete is undoable:
  /// the dialog is where the user learns that existing transactions keep their
  /// history, and undo is a safety net for a mis-tap, not a substitute for
  /// asking.
  Future<void> _delete(Category category) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings('categoriesDeleteConfirmTitle')),
        content: Text(strings('categoriesDeleteConfirmBody')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings('actionCancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings('actionDelete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    AppFeedback.destructive();
    await ref.read(deleteCategoryProvider).call((id: category.id));
    // A deleted row must not stay on screen in the detail pane.
    if (_paneCategory?.id == category.id) _closePane();
    if (!mounted) return;

    ref.invalidate(categoryListProvider);
    // The delete is a soft delete (`deletedAt`), so it is genuinely reversible
    // and the undo affordance is honest rather than decorative.
    AppFeedback.undoable(
      context,
      message: strings('categoriesDeleted'),
      undoLabel: undoLabelFor(context),
      onUndo: () => _restore(category),
    );
  }

  /// Restores a just-deleted category, the counterpart to the snack bar's undo.
  ///
  /// Failures are surfaced rather than swallowed: an undo that silently does
  /// nothing is worse than no undo, because the user believes the record is
  /// back.
  Future<void> _restore(Category category) async {
    final result = await ref.read(restoreCategoryProvider).call((
      id: category.id,
    ));
    ref.invalidate(categoryListProvider);
    if (!mounted) return;

    if (result.isSuccess) {
      AppFeedback.success();
      return;
    }
    AppFeedback.failure(
      context,
      message: AppStrings.of(context)('stateErrorBody'),
    );
  }

  /// Archives or unarchives, then refreshes the list.
  Future<void> _toggleArchive(Category category) async {
    AppFeedback.selection();
    await ref.read(setCategoryArchivedProvider).call((
      id: category.id,
      isArchived: !category.isArchived,
    ));
    ref.invalidate(categoryListProvider);
  }
}
