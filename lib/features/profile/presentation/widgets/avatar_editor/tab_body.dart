import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/editor_tab.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/tabs/colors_tab.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/tabs/face_tab.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/tabs/glasses_tab.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/tabs/head_tab.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/tabs/item_tab.dart';
import 'package:material_ui/material_ui.dart';

/// The main content area of the selected tab.
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class EditorTabBody extends StatelessWidget {
  /// Creates an [EditorTabBody].
  const EditorTabBody({
    required this.currentTab,
    required this.config,
    required this.onConfigChanged,
    super.key,
  });

  /// The active tab.
  final AvatarEditorTab currentTab;

  /// The working draft.
  final AvatarConfig config;

  /// Called with the updated draft.
  final ValueChanged<AvatarConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    return switch (currentTab) {
      AvatarEditorTab.head => HeadTab(
        config: config,
        onConfigChanged: onConfigChanged,
      ),
      AvatarEditorTab.face => FaceTab(
        config: config,
        onConfigChanged: onConfigChanged,
      ),
      AvatarEditorTab.glasses => GlassesTab(
        config: config,
        onConfigChanged: onConfigChanged,
      ),
      AvatarEditorTab.item => ItemTab(
        config: config,
        onConfigChanged: onConfigChanged,
      ),
      AvatarEditorTab.colors => ColorsTab(
        config: config,
        onConfigChanged: onConfigChanged,
      ),
    };
  }
}
