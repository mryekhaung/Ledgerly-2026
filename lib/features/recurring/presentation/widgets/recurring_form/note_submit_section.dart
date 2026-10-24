import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_text_field.dart';
import 'package:material_ui/material_ui.dart';

/// Note field, submit button and (when editing) the delete action.
///
/// Extracted from `recurring_form_page.dart` (`docs/Conventions.md` §1).
class RecurringNoteSubmitSection extends StatelessWidget {
  /// Creates a [RecurringNoteSubmitSection].
  const RecurringNoteSubmitSection({
    required this.noteController,
    required this.onNoteChanged,
    required this.isSubmitting,
    required this.isEditing,
    required this.onSubmit,
    required this.onDelete,
    super.key,
  });

  /// The note field controller (owned by the page).
  final TextEditingController noteController;

  /// Called with the note text.
  final ValueChanged<String> onNoteChanged;

  /// Whether a save is in flight.
  final bool isSubmitting;

  /// Whether an existing rule is being edited.
  final bool isEditing;

  /// Called to save.
  final VoidCallback onSubmit;

  /// Called to delete (after the page's own confirmation).
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Note input
        AppTextField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: strings('transactionNoteLabel'),
            hintText: strings('transactionNoteHint'),
            border: const OutlineInputBorder(borderRadius: AppRadius.borderMd),
          ),
          onChanged: onNoteChanged,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Submit button
        AppButton(
          label: strings('transactionSave'),
          onPressed: isSubmitting ? null : onSubmit,
          isLoading: isSubmitting,
          isExpanded: true,
        ),

        if (isEditing) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            variant: AppButtonVariant.destructive,
            onPressed: onDelete,
            label: strings('recurringActionDelete'),
            isExpanded: true,
          ),
        ],
      ],
    );
  }
}
