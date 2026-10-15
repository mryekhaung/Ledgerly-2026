import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/form_field_surface.dart';
import 'package:material_ui/material_ui.dart';

/// The date row: formatted day, opening the day picker on tap.
///
/// Extracted from `transaction_form_page.dart` (`docs/Conventions.md` §1).
class DateField extends StatelessWidget {
  /// Creates a [DateField].
  const DateField({required this.dateLabel, required this.onTap, super.key});

  /// The pre-formatted day label (CLDR via the page).
  final String dateLabel;

  /// Called to open the picker.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return FormFieldSurface(
      label: strings('transactionDateLabel'),
      value: dateLabel,
      trailing: const FormFieldChevron(),
      onTap: onTap,
    );
  }
}
