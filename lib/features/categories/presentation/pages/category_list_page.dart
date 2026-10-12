import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/category_list_state.dart';
import 'package:ledgerly/features/categories/presentation/pages/category_form_page.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_form_notifier.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_list_notifier.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/l10n/app_localization.dart';
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

    final body = switch (state) {
      AsyncData(:final value) => _CategoryListBody(
        state: value,
        onEdit: (category) => _openForm(existing: category),
        onDelete: (category) => _delete(category),
        onToggleArchive: (category) => _toggleArchive(category),
        selectedId: _paneEditing ? _paneCategory?.id : null,
      ),
      AsyncError() => StatePlaceholder(
        icon: Icons.error_outline,
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
      return Scaffold(
        appBar: AppBar(title: Text(strings('categoriesTitle'))),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: Text(strings('categoriesNew')),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 4, child: body),
            VerticalDivider(width: 1, color: AppThemeColors.of(context).border),
            Expanded(
              flex: 6,
              child: _DetailPane(editing: _paneEditing, onDismiss: _closePane),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings('categoriesTitle'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
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

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CategoryFormPage()));
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

/// The wide layout's right-hand pane: the form, or a hint to pick something.
class _DetailPane extends ConsumerWidget {
  const _DetailPane({required this.editing, required this.onDismiss});

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
        icon: Icons.edit_outlined,
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
          const Expanded(
            child: SingleChildScrollView(child: CategoryFormBody()),
          ),
        ],
      ),
    );
  }
}

/// The list body once data has arrived.
class _CategoryListBody extends StatelessWidget {
  const _CategoryListBody({
    required this.state,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleArchive,
    this.selectedId,
  });

  final CategoryListState state;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;
  final ValueChanged<Category> onToggleArchive;

  /// The row to highlight as open in the wide layout's detail pane, if any.
  ///
  /// Highlighting is the only affordance that tells the user *which* category
  /// the right-hand form belongs to, so it is not cosmetic.
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (state.isEmpty) {
      return StatePlaceholder(
        icon: Icons.category_outlined,
        title: strings('categoriesEmptyTitle'),
        body: strings('categoriesEmptyBody'),
      );
    }

    return CustomScrollView(
      // Bottom padding clears the extended FAB so the last row is reachable.
      slivers: <Widget>[
        if (state.failure case final failure?)
          SliverToBoxAdapter(
            child: ErrorBanner(
              message: strings(
                AppLocalization.failureKeyFor(failure.runtimeType.toString()),
              ),
            ),
          ),
        SliverList.builder(
          itemCount: state.active.length,
          itemBuilder: (context, index) => _CategoryRow(
            category: state.active[index],
            isOpen: state.active[index].id == selectedId,
            onEdit: onEdit,
            onDelete: onDelete,
            onToggleArchive: onToggleArchive,
          ),
        ),
        if (state.archived.isNotEmpty) ...<Widget>[
          SliverToBoxAdapter(
            child: _SectionHeader(label: strings('categoriesArchived')),
          ),
          SliverList.builder(
            itemCount: state.archived.length,
            itemBuilder: (context, index) => _CategoryRow(
              category: state.archived[index],
              isOpen: state.archived[index].id == selectedId,
              onEdit: onEdit,
              onDelete: onDelete,
              onToggleArchive: onToggleArchive,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

/// A small uppercase label above a section of the list.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppThemeColors.of(context).textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// One category row with a trailing overflow menu.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleArchive,
    this.isOpen = false,
  });

  final Category category;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;
  final ValueChanged<Category> onToggleArchive;

  /// Whether this row's form is currently in the wide layout's detail pane.
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return Material(
      // The selected-row tint is the only cue linking a list row to the form
      // beside it, so it is a real surface change rather than a subtle shade.
      color: isOpen ? colors.brandSubtle : Colors.transparent,
      child: InkWell(
        onTap: () => onEdit(category),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: CategoryGemLabel(
                  name: category.name,
                  colorValue: category.colorValue,
                  iconKey: category.iconKey,
                  size: CategoryGemSize.md,
                  subtitle: category.isArchived
                      ? strings('categoriesArchived')
                      : null,
                ),
              ),
              PopupMenuButton<_CategoryAction>(
                icon: Icon(Icons.more_horiz, color: colors.textSecondary),
                onSelected: (action) => switch (action) {
                  _CategoryAction.edit => onEdit(category),
                  _CategoryAction.toggleArchive => onToggleArchive(category),
                  _CategoryAction.delete => onDelete(category),
                },
                itemBuilder: (context) => <PopupMenuEntry<_CategoryAction>>[
                  PopupMenuItem<_CategoryAction>(
                    value: _CategoryAction.edit,
                    child: Text(strings('categoriesEdit')),
                  ),
                  PopupMenuItem<_CategoryAction>(
                    value: _CategoryAction.toggleArchive,
                    child: Text(
                      category.isArchived
                          ? strings('categoriesUnarchive')
                          : strings('categoriesArchive'),
                    ),
                  ),
                  PopupMenuItem<_CategoryAction>(
                    value: _CategoryAction.delete,
                    child: Text(strings('categoriesDelete')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the row's overflow menu can do.
enum _CategoryAction { edit, toggleArchive, delete }
