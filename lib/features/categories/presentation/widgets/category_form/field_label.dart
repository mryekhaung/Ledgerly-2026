import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A small label above a form section.
///
/// Extracted from `category_form_page.dart` (`docs/Conventions.md` §1).
class FieldLabel extends StatelessWidget {
  /// Creates a [FieldLabel].
  const FieldLabel({required this.label, super.key});

  /// The label text (already localized by the caller).
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppThemeColors.of(context).textTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}
