import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
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
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Note input
        TextField(
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
        FilledButton(
          onPressed: isSubmitting ? null : onSubmit,
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(strings('transactionSave')),
        ),

        if (isEditing) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.moneyOut,
              side: BorderSide(color: colors.moneyOut),
            ),
            onPressed: onDelete,
            child: Text(strings('recurringActionDelete')),
          ),
        ],
      ],
    );
  }
}
