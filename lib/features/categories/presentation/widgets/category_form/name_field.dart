import 'package:ledgerly/core/widgets/app_text_field.dart';
import 'package:material_ui/material_ui.dart';

/// The name field, owning its own [TextEditingController].
///
/// A `StatefulWidget` rather than a controller built inline in `build`: creating
/// one per rebuild would reset the cursor on every keystroke, and caching them
/// in a static map would leak one per page visit. This keeps the controller's
/// lifetime exactly the field's.
///
/// Extracted from `category_form_page.dart` (`docs/Conventions.md` §1).
class NameField extends StatefulWidget {
  /// Creates a [NameField].
  const NameField({
    required this.initialValue,
    required this.hintText,
    required this.errorText,
    required this.autofocus,
    required this.onChanged,
    super.key,
  });

  /// The initial name.
  final String initialValue;

  /// The hint text.
  final String hintText;

  /// The validation error, if any.
  final String? errorText;

  /// Whether to focus on first build.
  final bool autofocus;

  /// Called with the name text.
  final ValueChanged<String> onChanged;

  @override
  State<NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<NameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: _controller,
    autofocus: widget.autofocus,
    textInputAction: TextInputAction.done,
    maxLength: 60,
    onChanged: widget.onChanged,
    decoration: InputDecoration(
      hintText: widget.hintText,
      errorText: widget.errorText,
      counterText: '',
    ),
  );
}
