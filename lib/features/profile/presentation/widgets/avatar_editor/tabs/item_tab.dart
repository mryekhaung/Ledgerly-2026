import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/part_tile.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Item tab (None + Coming Soon placeholder).
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class ItemTab extends StatelessWidget {
  /// Creates an [ItemTab].
  const ItemTab({
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
    final colors = AppThemeColors.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal(width),
        vertical: AppSpacing.md,
      ),
      children: <Widget>[
        SizedBox(
          height: 100,
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 100,
                child: NoneTile(
                  isSelected: config.itemId == null,
                  onTap: () {
                    AppFeedback.selection();
                    onConfigChanged(config.copyWith(itemId: null));
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  AppIcons.sparkle,
                  size: 48,
                  color: colors.textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings('avatarEditorItemsComingSoon'),
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
