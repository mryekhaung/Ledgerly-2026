import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';

/// The 160 px circular live preview + Shuffle button.
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class EditorPreviewSection extends StatelessWidget {
  /// Creates an [EditorPreviewSection].
  const EditorPreviewSection({
    required this.config,
    required this.onShuffle,
    required this.saving,
    super.key,
  });

  /// The draft being previewed.
  final AvatarConfig config;

  /// Called when Shuffle is tapped.
  final VoidCallback onShuffle;

  /// Whether a save is in flight (disables shuffle).
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: AppSpacing.xxl),
          Avatar(
            config: config,
            size: 160,
            shape: AvatarShape.circle,
            semanticLabel: strings('profileAvatarLabel'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: saving ? null : onShuffle,
            icon: const Icon(AppIcons.shuffle, size: 18),
            label: Text(strings('avatarEditorRandom')),
          ),
        ],
      ),
    );
  }
}
