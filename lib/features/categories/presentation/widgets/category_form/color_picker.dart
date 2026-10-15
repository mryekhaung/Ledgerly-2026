import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/features/categories/presentation/category_catalog.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_form/selectable_cell.dart';
import 'package:material_ui/material_ui.dart';

/// The colour swatches.
///
/// Extracted from `category_form_page.dart` (`docs/Conventions.md` §1).
class CategoryColorPicker extends StatelessWidget {
  /// Creates a [CategoryColorPicker].
  const CategoryColorPicker({
    required this.selectedValue,
    required this.onSelected,
    super.key,
  });

  /// The selected ARGB32 color.
  final int selectedValue;

  /// Called with the picked value.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final value in CategoryPalette.colors)
          SelectableCell(
            isSelected: value == selectedValue,
            onTap: () => onSelected(value),
            // A ring rather than a checkmark: the swatch's own colour is the
            // content, so overlaying a glyph would hide what is being chosen.
            ringColor: colors.textPrimary,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(value),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
