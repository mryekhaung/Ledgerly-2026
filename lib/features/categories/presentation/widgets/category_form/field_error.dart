import 'package:material_ui/material_ui.dart';

/// An inline validation message.
///
/// Extracted from `category_form_page.dart` (`docs/Conventions.md` §1).
class FieldError extends StatelessWidget {
  /// Creates a [FieldError].
  const FieldError({required this.message, super.key});

  /// The localized message.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}
