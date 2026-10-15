import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/features/categories/presentation/category_catalog.dart';
import 'package:ledgerly/features/categories/presentation/widgets/category_form/selectable_cell.dart';
import 'package:material_ui/material_ui.dart';

/// The scrollable icon grid.
///
/// Extracted from `category_form_page.dart` (`docs/Conventions.md` §1).
class IconGrid extends StatelessWidget {
  /// Creates an [IconGrid].
  const IconGrid({
    required this.selectedKey,
    required this.onSelected,
    super.key,
  });

  /// The selected icon key.
  final String selectedKey;

  /// Called with the picked key.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final key in CategoryIcons.keys)
          SelectableCell(
            isSelected: key == selectedKey,
            onTap: () => onSelected(key),
            child: Icon(
              CategoryIcons.iconFor(key),
              size: 20,
              color: key == selectedKey
                  ? colors.textOnBrand
                  : colors.textSecondary,
            ),
          ),
      ],
    );
  }
}
