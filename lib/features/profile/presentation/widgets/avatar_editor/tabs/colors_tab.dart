import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_palette.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Colors tab (Background, Outline, Hair, Skin tone, Outfit).
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class ColorsTab extends StatelessWidget {
  /// Creates a [ColorsTab].
  const ColorsTab({
    required this.config,
    required this.onConfigChanged,
    super.key,
  });

  /// The working draft.
  final AvatarConfig config;

  /// Called with the updated draft.
  final ValueChanged<AvatarConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: <Widget>[
        _ColorSection(
          label: strings('avatarEditorBackground'),
          colors: AvatarPalette.backgrounds,
          selectedColor: config.colors.background,
          onColorSelected: (argb) {
            AppFeedback.selection();
            onConfigChanged(
              config.copyWith(colors: config.colors.copyWith(background: argb)),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _ColorSection(
          label: strings('avatarEditorColorOutline'),
          colors: AvatarPalette.inks,
          selectedColor: config.colors.ink,
          onColorSelected: (argb) {
            AppFeedback.selection();
            onConfigChanged(
              config.copyWith(colors: config.colors.copyWith(ink: argb)),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _ColorSection(
          label: strings('avatarEditorColorHair'),
          colors: AvatarPalette.hairs,
          selectedColor: config.colors.hair,
          onColorSelected: (argb) {
            AppFeedback.selection();
            onConfigChanged(
              config.copyWith(colors: config.colors.copyWith(hair: argb)),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _ColorSection(
          label: strings('avatarEditorColorSkin'),
          colors: AvatarPalette.skins,
          selectedColor: config.colors.skin,
          onColorSelected: (argb) {
            AppFeedback.selection();
            onConfigChanged(
              config.copyWith(colors: config.colors.copyWith(skin: argb)),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _ColorSection(
          label: strings('avatarEditorColorOutfit'),
          colors: AvatarPalette.outfits,
          selectedColor: config.colors.clothing,
          onColorSelected: (argb) {
            AppFeedback.selection();
            onConfigChanged(
              config.copyWith(colors: config.colors.copyWith(clothing: argb)),
            );
          },
        ),
      ],
    );
  }
}

/// One swatch section: header + horizontal strip of circles.
class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.label,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final String label;
  final List<int> colors;
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final themeColors = AppThemeColors.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(width),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal(width),
            ),
            itemCount: colors.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final argb = colors[index];
              final isSelected = argb == selectedColor;
              return _ColorSwatch(
                argb: argb,
                isSelected: isSelected,
                onTap: () => onColorSelected(argb),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A circular color swatch with selected ring.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.argb,
    required this.isSelected,
    required this.onTap,
  });

  final int argb;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeColors = AppThemeColors.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderFull,
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? themeColors.brandPrimary : themeColors.border,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(argb),
            ),
          ),
        ),
      ),
    );
  }
}
