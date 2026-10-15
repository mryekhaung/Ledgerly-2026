import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/part_tile.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Face tab: Expressions (30 variants) + Facial Hair (16 variants + None).
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class FaceTab extends StatelessWidget {
  /// Creates a [FaceTab].
  const FaceTab({
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

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(width),
            vertical: AppSpacing.md,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final faceId = AvatarCatalog.expressions[index];
              final isSelected = config.faceId == faceId;
              return PartTile(
                group: 'expression',
                id: faceId,
                isSelected: isSelected,
                config: config.copyWith(faceId: faceId),
                semanticLabel: AppStrings.fill(
                  context,
                  'avatarEditorOptionLabel',
                  {'part': strings('avatarEditorTabFace'), 'number': index + 1},
                ),
                onTap: () {
                  AppFeedback.selection();
                  onConfigChanged(config.copyWith(faceId: faceId));
                },
              );
            }, childCount: AvatarCatalog.expressions.length),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal(width),
              vertical: AppSpacing.md,
            ),
            child: Text(
              strings('avatarEditorBeard').toUpperCase(),
              style: AppTypography.overline.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            left: AppSpacing.pageHorizontal(width),
            right: AppSpacing.pageHorizontal(width),
            bottom: AppSpacing.lg,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == 0) {
                final isNone = config.facialHairId == null;
                return NoneTile(
                  isSelected: isNone,
                  onTap: () {
                    AppFeedback.selection();
                    onConfigChanged(config.copyWith(facialHairId: null));
                  },
                );
              }
              final beardId = AvatarCatalog.facialHairs[index - 1];
              final isSelected = config.facialHairId == beardId;
              return PartTile(
                group: 'facial_hair',
                id: beardId,
                isSelected: isSelected,
                config: config.copyWith(facialHairId: beardId),
                semanticLabel: AppStrings.fill(
                  context,
                  'avatarEditorOptionLabel',
                  {'part': strings('avatarEditorBeard'), 'number': index},
                ),
                onTap: () {
                  AppFeedback.selection();
                  onConfigChanged(config.copyWith(facialHairId: beardId));
                },
              );
            }, childCount: AvatarCatalog.facialHairs.length + 1),
          ),
        ),
      ],
    );
  }
}
