import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/presentation/category_catalog.dart';
import 'package:material_ui/material_ui.dart';

/// The goal icon picker: a curated subset of the category vocabulary.
///
/// Keys must be `CategoryIcons` vocabulary keys — anything else renders as the
/// fallback glyph for every option (guarded by `category_catalog_test.dart`).
const List<String> kGoalIcons = <String>[
  'savings',
  'invest',
  'travel',
  'car',
  'home',
  'education',
  'shopping',
  'gift',
];

/// Icon + color pickers.
///
/// Extracted from `goal_form_page.dart` (`docs/Conventions.md` §1).
class GoalIconColorSection extends StatelessWidget {
  /// Creates a [GoalIconColorSection].
  const GoalIconColorSection({
    required this.iconKey,
    required this.colorValue,
    required this.onIconChanged,
    required this.onColorChanged,
    super.key,
  });

  /// The current icon key.
  final String iconKey;

  /// The current ARGB32 color.
  final int colorValue;

  /// Called with the picked icon key.
  final ValueChanged<String> onIconChanged;

  /// Called with the picked color value.
  final ValueChanged<int> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Icon Picker
        Text(
          strings('goalIconLabel'),
          style: AppTypography.body.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final key in kGoalIcons)
              GestureDetector(
                onTap: () => onIconChanged(key),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconKey == key
                        ? colors.moneyIn.withValues(alpha: 0.2)
                        : colors.surfaceRaised,
                    border: Border.all(
                      color: iconKey == key ? colors.moneyIn : colors.border,
                      width: iconKey == key ? 2 : 1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CategoryGem(
                    colorValue: colorValue,
                    iconKey: key,
                    size: CategoryGemSize.md,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Color Picker
        Text(
          strings('goalColorLabel'),
          style: AppTypography.body.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            // The shared category palette: goals render through
            // `CategoryGem`, so they pick from the same family.
            for (final colorVal in CategoryPalette.colors)
              GestureDetector(
                onTap: () => onColorChanged(colorVal),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(colorVal),
                    shape: BoxShape.circle,
                    // Selection is the 3 px ring alone: §4.3 allows only
                    // flat/raised/floating elevation, not a bespoke glow.
                    border: colorValue == colorVal
                        ? Border.all(color: colors.textOnBrand, width: 3)
                        : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
