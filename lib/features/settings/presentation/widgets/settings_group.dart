import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A titled group of rows with the standard card treatment.
///
/// Extracted from `settings_page.dart` (`docs/Conventions.md` §1).
class SettingsGroup extends StatelessWidget {
  /// Creates a [SettingsGroup].
  const SettingsGroup({required this.children, super.key});

  /// The rows inside the group.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.border),
        boxShadow: AppElevation.raised(colors),
      ),
      // ClipBehaviour via the decoration's radius: a row's ink splash would
      // otherwise paint square corners over the rounded card.
      child: ClipRRect(
        borderRadius: AppRadius.borderLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// A hairline between rows inside a group.
///
/// Extracted from `settings_page.dart` (`docs/Conventions.md` §1).
class GroupDivider extends StatelessWidget {
  /// Creates a [GroupDivider].
  const GroupDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: AppSpacing.lg,
    color: AppThemeColors.of(context).border,
  );
}

/// A small uppercase section label above a group.
///
/// Extracted from `settings_page.dart` (`docs/Conventions.md` §1).
class SectionHeader extends StatelessWidget {
  /// Creates a [SectionHeader].
  const SectionHeader({required this.label, super.key});

  /// The section title.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colors.textSecondary, letterSpacing: 0.8),
      ),
    );
  }
}
