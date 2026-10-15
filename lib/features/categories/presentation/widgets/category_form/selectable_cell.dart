import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A tappable square that shows selected state.
///
/// Shared by the icon grid and the colour palette so both are the same hit
/// target size and the same focus/selection affordance
/// (`docs/Platform.md` — 44pt minimum touch target).
///
/// Extracted from `category_form_page.dart` (`docs/Conventions.md` §1).
class SelectableCell extends StatelessWidget {
  /// Creates a [SelectableCell].
  const SelectableCell({
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.ringColor,
    super.key,
  });

  /// Whether this cell is the current choice.
  final bool isSelected;

  /// Called when the cell is tapped.
  final VoidCallback onTap;

  /// The cell content.
  final Widget child;

  /// Selection ring override (defaults to brand).
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderFull,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? colors.brandPrimary : colors.surfaceRaised,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? (ringColor ?? colors.brandPrimary)
                : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
