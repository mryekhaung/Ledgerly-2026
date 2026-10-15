import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/core/widgets/form_field_surface.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:material_ui/material_ui.dart';

/// The category row: gem + name, opening the picker on tap.
///
/// Extracted from `transaction_form_page.dart` (`docs/Conventions.md` §1).
class CategoryField extends StatelessWidget {
  /// Creates a [CategoryField].
  const CategoryField({
    required this.category,
    required this.isError,
    required this.onTap,
    super.key,
  });

  /// The chosen category, if any.
  final Category? category;

  /// Whether the field is in error.
  final bool isError;

  /// Called to open the picker.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final category = this.category;

    return FormFieldSurface(
      label: strings('transactionCategoryLabel'),
      value: category?.name,
      leading: category == null
          ? null
          : CategoryGem(
              colorValue: category.colorValue,
              iconKey: category.iconKey,
              size: CategoryGemSize.md,
            ),
      trailing: const FormFieldChevron(),
      isError: isError,
      onTap: onTap,
    );
  }
}
