import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A 44 px selectable cell for the icon picker grid.
///
/// Extracted from `account_form_page.dart` (`docs/Conventions.md` §1).
class SelectableCell extends StatelessWidget {
  /// Creates a [SelectableCell].
  const SelectableCell({
    required this.isSelected,
    required this.onTap,
    required this.child,
    super.key,
  });

  /// Whether this cell is the current choice.
  final bool isSelected;

  /// Called when the cell is tapped.
  final VoidCallback onTap;

  /// The cell content (usually an icon).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? colors.brandPrimary : colors.surfaceSubtle,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isSelected ? colors.brandPrimary : colors.border,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
