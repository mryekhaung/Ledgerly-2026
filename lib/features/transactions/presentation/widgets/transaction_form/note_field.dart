import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// The free-text note field.
///
/// Owns its own [TextEditingController] rather than receiving one, so the
/// controller's lifetime is exactly the widget's — a controller created in
/// `build` resets the cursor on every keystroke, and one cached in a static
/// map leaks a controller per page visit.
///
/// Extracted from `transaction_form_page.dart` (`docs/Conventions.md` §1).
class NoteField extends StatefulWidget {
  /// Creates a [NoteField].
  const NoteField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    super.key,
  });

  /// The field controller (owned by the page).
  final TextEditingController controller;

  /// The hint text.
  final String hint;

  /// Called with the note text.
  final ValueChanged<String> onChanged;

  @override
  State<NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<NoteField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        maxLines: 2,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        style: theme.textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
        cursorColor: colors.brandPrimary,
        // `border: InputBorder.none` is the point of this widget: the fill and
        // radius come from the container above, per `docs/Design.md` §5.8, which
        // forbids outline boxes.
        decoration: InputDecoration.collapsed(
          hintText: widget.hint,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ),
    );
  }
}
