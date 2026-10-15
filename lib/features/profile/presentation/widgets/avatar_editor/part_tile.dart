import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';

/// A single option tile in a 3-column grid.
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class PartTile extends StatelessWidget {
  /// Creates a [PartTile].
  const PartTile({
    required this.group,
    required this.id,
    required this.isSelected,
    required this.config,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  /// The part group (`head`, `expression`, …).
  final String group;

  /// The option id within the group.
  final String id;

  /// Whether this option is the current choice.
  final bool isSelected;

  /// The draft with this option applied (rendered as the thumbnail).
  final AvatarConfig config;

  /// Screen-reader label.
  final String semanticLabel;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            color: colors.surfaceSubtle,
            border: Border.all(
              color: isSelected ? colors.brandPrimary : colors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xs),
          alignment: Alignment.center,
          child: Avatar(
            config: config,
            size: 64,
            shape: AvatarShape.circle,
            thumbnailGroup: group,
            thumbnailId: id,
          ),
        ),
      ),
    );
  }
}

/// The "None" (⊘) tile for optional layers.
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class NoneTile extends StatelessWidget {
  /// Creates a [NoneTile].
  const NoneTile({required this.isSelected, required this.onTap, super.key});

  /// Whether "none" is the current choice.
  final bool isSelected;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: strings('avatarEditorNone'),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            color: colors.surfaceSubtle,
            border: Border.all(
              color: isSelected ? colors.brandPrimary : colors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                AppIcons.blocked,
                color: isSelected ? colors.brandPrimary : colors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                strings('avatarEditorNone'),
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? colors.brandPrimary
                      : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
