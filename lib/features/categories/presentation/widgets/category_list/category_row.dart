import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:material_ui/material_ui.dart';

/// One category row with a trailing overflow menu.
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
              PopupMenuButton<CategoryAction>(
                icon: Icon(
                  AppIcons.moreHorizontal,
                  color: colors.textSecondary,
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// What the row's overflow menu can do.
enum CategoryAction { edit, toggleArchive, delete }
