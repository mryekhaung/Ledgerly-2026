import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A small uppercase label above a section of the list.
///
/// Extracted from `category_list_page.dart` (`docs/Conventions.md` §1).
class CategorySectionHeader extends StatelessWidget {
  /// Creates a [CategorySectionHeader].
  const CategorySectionHeader({required this.label, super.key});

  /// The section title.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppThemeColors.of(context).textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
