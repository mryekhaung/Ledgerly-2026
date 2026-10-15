import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:material_ui/material_ui.dart';

/// Picks a category for the transaction being entered.
///
/// A full page rather than a dropdown or a bottom sheet: the list is long enough
/// to scroll, the user needs to read names *and* see colours, and a picker that
/// an accidental scrim tap could dismiss would throw away a half-entered amount.
///
/// Shows only categories usable for the transaction's direction — offering an
/// income category on an expense is a mistake the picker can prevent outright
/// (`docs/DataModel.md` §2: `kind` exists to classify exactly this).
///
/// Pops the chosen [Category], or null when dismissed.
class CategoryPickerPage extends ConsumerWidget {
  /// Creates the picker.
  const CategoryPickerPage({required this.kind, this.selectedId, super.key});

  /// Which direction's categories to offer.
  final CategoryKind kind;

  /// The currently chosen category, shown as selected.
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final stream = ref.watch(watchPickableCategoriesProvider).call((
      kind: kind,
    ));

    return AppScaffold(
      title: strings('transactionCategoryChoose'),
      // A `Result` stream: the failure is a value, so the error branch renders
      // without an exception ever escaping `data/`
      // (`docs/Architecture.md` §8).
      body: StreamBuilder<Result<List<Category>>>(
        stream: stream,
        builder: (context, snapshot) {
          final result = snapshot.data;
          if (result == null) return const LoadingPlaceholder();

          return result.fold(
            onSuccess: (categories) => categories.isEmpty
                ? StatePlaceholder(
                    icon: AppIcons.category,
                    title: strings('categoriesEmptyTitle'),
                    body: strings('categoriesEmptyBody'),
                  )
                : _CategoryList(categories: categories, selectedId: selectedId),
            onErr: (failure) => StatePlaceholder(
              icon: AppIcons.error,
              title: strings('stateErrorTitle'),
              body: strings(
                AppLocalization.failureKeyFor(failure.runtimeType.toString()),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The scrollable category list.
class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories, this.selectedId});

  final List<Category> categories;
  final String? selectedId;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    itemCount: categories.length,
    itemBuilder: (context, index) => _PickerRow(
      category: categories[index],
      isSelected: categories[index].id == selectedId,
    ),
  );
}

/// One selectable category.
class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.category, required this.isSelected});

  final Category category;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return ListTile(
      onTap: () => Navigator.of(context).pop(category),
      leading: CategoryGem(
        colorValue: category.colorValue,
        iconKey: category.iconKey,
        size: CategoryGemSize.md,
      ),
      title: Text(category.name),
      trailing: isSelected
          ? Icon(AppIcons.check, color: colors.brandPrimary)
          : null,
      selected: isSelected,
    );
  }
}
