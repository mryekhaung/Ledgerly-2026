import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/part_tile.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Glasses tab (8 accessory variants + None).
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class GlassesTab extends StatelessWidget {
  /// Creates a [GlassesTab].
  const GlassesTab({
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
      itemCount: AvatarCatalog.accessories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final isNone = config.accessoryId == null;
          return NoneTile(
            isSelected: isNone,
            onTap: () {
              AppFeedback.selection();
              onConfigChanged(config.copyWith(accessoryId: null));
            },
          );
        }
        final accId = AvatarCatalog.accessories[index - 1];
        final isSelected = config.accessoryId == accId;
        return PartTile(
          group: 'accessories',
          id: accId,
          isSelected: isSelected,
          config: config.copyWith(accessoryId: accId),
          semanticLabel: AppStrings.fill(context, 'avatarEditorOptionLabel', {
            'part': strings('avatarEditorTabGlasses'),
            'number': index,
          }),
          onTap: () {
            AppFeedback.selection();
            onConfigChanged(config.copyWith(accessoryId: accId));
          },
        );
      },
    );
  }
}
