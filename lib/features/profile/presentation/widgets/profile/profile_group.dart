import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A group of rows with the standard raised-card treatment.
///
/// Matches the settings group deliberately: the two pages sit next to each
/// other in the back stack and a different card treatment between them would
/// read as two design languages. Kept local (rather than importing the
/// settings one) so neither feature depends on the other's presentation layer
/// (`docs/Conventions.md` §2).
///
/// Extracted from `profile_page.dart` (`docs/Conventions.md` §1).
class ProfileGroup extends StatelessWidget {
  /// Creates a [ProfileGroup].
  const ProfileGroup({required this.children, super.key});

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
/// Extracted from `profile_page.dart` (`docs/Conventions.md` §1).
class ProfileGroupDivider extends StatelessWidget {
  /// Creates a [ProfileGroupDivider].
  const ProfileGroupDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: AppSpacing.lg,
    color: AppThemeColors.of(context).border,
  );
}
