import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/part_tile.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Head options (48 variants).
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class HeadTab extends StatelessWidget {
  /// Creates a [HeadTab].
  const HeadTab({
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
    final width = MediaQuery.sizeOf(context).width;

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal(width),
        vertical: AppSpacing.md,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemCount: AvatarCatalog.heads.length,
      itemBuilder: (context, index) {
        final headId = AvatarCatalog.heads[index];
        final isSelected = config.headId == headId;
        return PartTile(
          group: 'head',
          id: headId,
          isSelected: isSelected,
          config: config.copyWith(headId: headId),
          semanticLabel: AppStrings.fill(context, 'avatarEditorOptionLabel', {
            'part': AppStrings.of(context)('avatarEditorTabHead'),
            'number': index + 1,
          }),
          onTap: () {
            AppFeedback.selection();
            onConfigChanged(config.copyWith(headId: headId));
          },
        );
      },
    );
  }
}
