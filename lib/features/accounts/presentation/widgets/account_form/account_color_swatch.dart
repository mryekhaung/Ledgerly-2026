import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A circular color swatch with a 3 px selection ring.
///
/// Selection is the ring alone: §4.3 allows only flat/raised/floating
/// elevation, and a bespoke glow would be a fourth level.
///
/// Extracted from `account_form_page.dart` (`docs/Conventions.md` §1).
class AccountColorSwatch extends StatelessWidget {
  /// Creates an [AccountColorSwatch].
  const AccountColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// The swatch color.
  final Color color;

  /// Whether this color is the current choice.
  final bool isSelected;

  /// Called when the swatch is tapped.
  final VoidCallback onTap;

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
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: colors.textOnBrand, width: 3)
              : null,
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  AppIcons.check,
                  size: 20,
                  color: colors.textOnBrand,
                ),
              )
            : null,
      ),
    );
  }
}
