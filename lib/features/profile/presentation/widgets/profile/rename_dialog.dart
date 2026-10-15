import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/usecases/save_display_name.dart';
import 'package:material_ui/material_ui.dart';

/// The rename dialog: one field, validated on submit by the use case.
///
/// The dialog itself does not validate — [SaveDisplayName] owns the rules, and
/// duplicating them here is how the two drift apart. It only enforces the length
/// cap on the field so the user cannot type past it.
///
/// Extracted from `profile_page.dart` (`docs/Conventions.md` §1).
class RenameDialog extends StatefulWidget {
  /// Creates a [RenameDialog].
  const RenameDialog({required this.initial, super.key});

  /// The current name seeding the field.
  final String initial;

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AlertDialog(
      title: Text(strings('profileEditName')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: SaveDisplayName.maxLength,
        textInputAction: TextInputAction.done,
        // Submits on Enter, so a keyboard user never has to reach for the button.
        onSubmitted: (value) => Navigator.of(context).pop(value),
        decoration: InputDecoration(
          labelText: strings('profileNameLabel'),
          hintText: strings('profileNameHint'),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings('actionCancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(strings('actionSave')),
        ),
      ],
    );
  }
}
