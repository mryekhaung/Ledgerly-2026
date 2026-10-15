import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/core/widgets/list_row.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:material_ui/material_ui.dart';

/// One category row with a trailing overflow menu.
///
/// A [ListRow] (`docs/Design.md` §5.6) — 64/76 px height, lg/md padding, the
/// press wash — wrapped in the open-row tint when the wide layout shows this
/// row's form beside it.
///
/// Extracted from `category_list_page.dart` (`docs/Conventions.md` §1).
class CategoryRow extends StatelessWidget {
  /// Creates a [CategoryRow].
  const CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleArchive,
    this.isOpen = false,
    super.key,
  });

  /// The category this row renders.
  final Category category;

  /// Called to edit the category.
  final ValueChanged<Category> onEdit;

  /// Called to delete the category.
  final ValueChanged<Category> onDelete;

  /// Called to archive/unarchive the category.
  final ValueChanged<Category> onToggleArchive;

  /// Whether this row's form is currently in the wide layout's detail pane.
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return Container(
      // The selected-row tint is the only cue linking a list row to the form
      // beside it, so it is a real surface change rather than a subtle shade.
      color: isOpen ? colors.brandSubtle : Colors.transparent,
      child: ListRow(
        leading: CategoryGem(
          colorValue: category.colorValue,
          iconKey: category.iconKey,
          size: CategoryGemSize.md,
        ),
        title: Text(category.name),
        subtitle: category.isArchived
            ? Text(strings('categoriesArchived'))
            : null,
        trailing: PopupMenuButton<CategoryAction>(
          icon: Icon(AppIcons.moreHorizontal, color: colors.textSecondary),
          onSelected: (action) => switch (action) {
            CategoryAction.edit => onEdit(category),
            CategoryAction.toggleArchive => onToggleArchive(category),
            CategoryAction.delete => onDelete(category),
          },
          itemBuilder: (context) => <PopupMenuEntry<CategoryAction>>[
            PopupMenuItem<CategoryAction>(
              value: CategoryAction.edit,
              child: Text(strings('categoriesEdit')),
            ),
            PopupMenuItem<CategoryAction>(
              value: CategoryAction.toggleArchive,
              child: Text(
                category.isArchived
                    ? strings('categoriesUnarchive')
                    : strings('categoriesArchive'),
              ),
            ),
            PopupMenuItem<CategoryAction>(
              value: CategoryAction.delete,
              child: Text(strings('categoriesDelete')),
            ),
          ],
        ),
        onTap: () => onEdit(category),
        semanticsLabel: category.name,
      ),
    );
  }
}

/// What the row's overflow menu can do.
enum CategoryAction { edit, toggleArchive, delete }
