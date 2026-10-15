import 'package:ledgerly/core/widgets/form_field_surface.dart';
import 'package:material_ui/material_ui.dart';

/// A field plus its inline error.
///
/// The visible label lives inside the field itself (`FormFieldSurface`), so
/// this wrapper only pairs the two.
///
/// Extracted from `transaction_form_page.dart` (`docs/Conventions.md` §1).
class FieldGroup extends StatelessWidget {
  /// Creates a [FieldGroup].
  const FieldGroup({required this.field, this.error, super.key});

  /// The field widget.
  final Widget field;

  /// The inline validation error, if any.
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      field,
      if (error case final message?) FormFieldError(message: message),
    ],
  );
}
