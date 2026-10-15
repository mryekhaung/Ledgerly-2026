import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/editor_tab.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Horizontal scrollable chip row for the 5 tabs (docs/Design.md §5.5).
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class EditorTabChipsRow extends StatelessWidget {
  /// Creates an [EditorTabChipsRow].
  const EditorTabChipsRow({
    required this.currentTab,
    required this.onTabSelected,
    super.key,
  });

  /// The active tab.
  final AvatarEditorTab currentTab;

  /// Called when a tab chip is tapped.
  final ValueChanged<AvatarEditorTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal(width),
      ),
      child: Row(
        children: <Widget>[
          for (final tab in AvatarEditorTab.values) ...<Widget>[
            _TabChip(
              tab: tab,
              label: strings(_tabLabelKey(tab)),
              isSelected: tab == currentTab,
              onTap: () {
                AppFeedback.selection();
                onTabSelected(tab);
              },
            ),
            if (tab != AvatarEditorTab.colors)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  static String _tabLabelKey(AvatarEditorTab tab) => switch (tab) {
    AvatarEditorTab.head => 'avatarEditorTabHead',
    AvatarEditorTab.face => 'avatarEditorTabFace',
    AvatarEditorTab.glasses => 'avatarEditorTabGlasses',
    AvatarEditorTab.item => 'avatarEditorTabItem',
    AvatarEditorTab.colors => 'avatarEditorTabColors',
  };
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.tab,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final AvatarEditorTab tab;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderFull,
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.standard,
          height: 36,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderFull,
            color: isSelected ? colors.brandSubtle : Colors.transparent,
            border: Border.all(
              color: isSelected ? colors.brandPrimary : colors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: isSelected ? colors.brandPrimary : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
