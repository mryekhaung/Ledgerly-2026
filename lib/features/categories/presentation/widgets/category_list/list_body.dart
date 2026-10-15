import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/category_list_state.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_list/category_row.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_list/section_header.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:material_ui/material_ui.dart';

/// The list body once data has arrived.
///
/// Extracted from `category_list_page.dart` (`docs/Conventions.md` §1).
class CategoryListBody extends StatelessWidget {
  /// Creates a [CategoryListBody].
  const CategoryListBody({
    required this.state,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleArchive,
    this.selectedId,
    super.key,
  });

  /// The loaded list state.
  final CategoryListState state;

  /// Called to edit a category.
  final ValueChanged<Category> onEdit;

  /// Called to delete a category.
  final ValueChanged<Category> onDelete;

  /// Called to archive/unarchive a category.
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
        icon: AppIcons.category,
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
          itemBuilder: (context, index) => CategoryRow(
            category: state.active[index],
            isOpen: state.active[index].id == selectedId,
            onEdit: onEdit,
            onDelete: onDelete,
            onToggleArchive: onToggleArchive,
          ),
        ),
        if (state.archived.isNotEmpty) ...<Widget>[
          SliverToBoxAdapter(
            child: CategorySectionHeader(label: strings('categoriesArchived')),
          ),
          SliverList.builder(
            itemCount: state.archived.length,
            itemBuilder: (context, index) => CategoryRow(
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
