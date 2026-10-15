import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:material_ui/material_ui.dart';

/// A small overline field label.
///
/// Extracted from `account_form_page.dart` (`docs/Conventions.md` §1).
class FieldLabel extends StatelessWidget {
  /// Creates a [FieldLabel].
  const FieldLabel({required this.label, super.key});

  /// The label text (already localized by the caller).
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.overline.copyWith(
        color: AppThemeColors.of(context).textTertiary,
      ),
    );
  }
}
